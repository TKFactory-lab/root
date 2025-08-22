#!/usr/bin/env ruby
# scripts/process_rfps.rb
# Find RFP issues in crewai-rfps project that are in Submitted status and not processed,
# create a new project from template and mark RFP as Accepted/linked.
require File.expand_path('../config/environment', __dir__)
require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

log = []

# Helper: mask secrets for logs (keep last N chars)
def mask_secret(s, keep=4)
  return nil if s.nil?
  begin
    s.to_s.gsub(/.(?=.{#{keep}})/, '*')
  rescue
    '[MASKING_ERROR]'
  end
end

# Helper: redact key=... query values from URLs for safe logging
def sanitize_url_for_log(url)
  return nil if url.nil? || url.empty?
  begin
    # remove query parameter values for 'key'
    url.sub(/([?&]key=)[^&]+/, '\1[REDACTED]')
  rescue
    '[URL_SANITIZE_ERROR]'
  end
end

def post_to_agent(endpoint, token, payload, log)
  return unless endpoint && !endpoint.empty?
  begin
    uri = URI.parse(endpoint)
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = "Bearer #{token}" if token && !token.empty?
    req.body = payload.to_json
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      res = http.request(req)
      log << "AGENT_WEBHOOK_RESPONSE: #{res.code} #{res.message}"
      log << "AGENT_WEBHOOK_BODY: #{res.body}" if res.body && !res.body.empty?
    end
  rescue => ex
    log << "AGENT_WEBHOOK_ERROR: #{ex.class}: #{ex.message}"
  end
end

begin
  intake = Project.find_by(identifier: 'crewai-rfps')
  template = Project.find_by(identifier: 'tkfactorylab-scrum-template')
  raise 'intake or template missing' unless intake && template
  submitted = IssueStatus.find_by(name: 'Submitted')
  accepted = IssueStatus.find_by(name: 'Accepted')
  raise 'statuses missing' unless submitted && accepted

  # simple processed marker: a custom field or note. For now use issue.notes to detect
  intake.issues.where(tracker: Tracker.find_by(name: 'RFP'), status_id: submitted.id).each do |rfp|
    log << "PROCESSING_RFP: #{rfp.id}: #{rfp.subject}"
    # create project from subject (sanitized identifier)
  # sanitize subject into a safe identifier (lowercase, hyphens, strip leading/trailing hyphens)
  identifier = rfp.subject.to_s.downcase.gsub(/[^a-z0-9]+/,'-').gsub(/(^-|-$)/,'').slice(0,50)
    # ensure unique
    base = "rfp-#{identifier}"
    ident = base
    i = 1
    while Project.find_by(identifier: ident)
      ident = "#{base}-#{i}"
      i += 1
    end
    new_proj = Project.new(name: rfp.subject, identifier: ident, description: "Created from RFP ##{rfp.id}")
    new_proj.is_public = false
    new_proj.trackers = template.trackers
    new_proj.enabled_module_names = template.enabled_module_names
    new_proj.save!
    log << "CREATED_PROJECT: #{new_proj.id} #{new_proj.identifier} from rfp #{rfp.id}"

    # copy categories and versions
    template.issue_categories.each do |c|
      new_proj.issue_categories.create!(name: c.name)
    end
    template.versions.each do |v|
      new_proj.versions.create!(name: v.name, due_date: v.due_date, status: v.status)
    end
    log << "COPIED_METADATA: categories=#{new_proj.issue_categories.map(&:name).join(', ')} versions=#{new_proj.versions.map(&:name).join(', ')}"

    # add nobu as project lead (if present)
    nb = User.find_by(login: 'nobu')
    pl = Role.find_by(name: 'Project Lead')
    if nb && pl
      Member.create!(project_id: new_proj.id, user_id: nb.id, role_ids: [pl.id])
      log << "ADDED_NOBU_LEAD: nobu->#{new_proj.identifier}"
    else
      log << "MISSING_NOBU_OR_PL"
    end

    # Add AI agent watchers (configurable via ENV). Default agents: nobu,hide,yasu
    agent_logins = (ENV['CREWAI_AGENT_USERS'] || 'nobu,hide,yasu').split(',').map(&:strip)
    recipients = []
    agent_logins.each do |login|
      begin
        u = User.find_by(login: login)
        if u
          # add watcher to the RFP issue so agent U receives updates in Redmine UI
          begin
            if defined?(Watcher)
              unless Watcher.where(user_id: u.id, watchable_type: rfp.class.name, watchable_id: rfp.id).exists?
                Watcher.create!(user: u, watchable: rfp)
                log << "ADDED_WATCHER: #{login}->issue#{rfp.id}"
              else
                log << "WATCHER_EXISTS: #{login}->issue#{rfp.id}"
              end
            end
          rescue => wex
            log << "WATCHER_ERROR: #{login}: #{wex.class}: #{wex.message}"
          end
          recipients << login
        else
          log << "MISSING_AGENT_USER: #{login}"
        end
      rescue => ex
        log << "AGENT_LOOKUP_ERROR: #{login}: #{ex.class}: #{ex.message}"
      end
    end

    # link rfp to project (note and change status to Accepted)
    rfp.init_journal(nb || User.anonymous, "Auto-created project #{new_proj.identifier}")
    rfp.status = accepted
    rfp.save!
    log << "RFP_MARKED_ACCEPTED: #{rfp.id} -> status=#{rfp.status.name} linked_project=#{new_proj.identifier}"

    # notify CrewAI agent via webhook (if configured)
    agent_endpoint = ENV['CREWAI_AGENT_WEBHOOK']
    agent_token = ENV['CREWAI_AGENT_TOKEN']
    redmine_url = ENV['REDMINE_URL'] || ''
    api_key = ENV['REDMINE_API_KEY'] || ''
    attachments = rfp.attachments.map do |a|
      url = nil
      if redmine_url && !redmine_url.empty?
        if api_key && !api_key.empty?
          url = "#{redmine_url}/attachments/download/#{a.id}?key=#{api_key}"
        else
          url = "#{redmine_url}/attachments/download/#{a.id}"
        end
      end
      { filename: a.filename, url: url }
    end
    payload = {
      event: 'rfp_created',
      issue: { id: rfp.id, subject: rfp.subject, url: (redmine_url.empty? ? nil : "#{redmine_url}/issues/#{rfp.id}") },
      project: { id: new_proj.id, identifier: new_proj.identifier },
      attachments: attachments,
      recipients: recipients # list of agent logins we attempted to notify / add as watchers
    }
  # log environment and outgoing payload for debugging (mask secrets)
  log << "ENV_CREWAI_AGENT_WEBHOOK=#{agent_endpoint}" if agent_endpoint && !agent_endpoint.empty?
  if agent_token && !agent_token.empty?
    log << "ENV_CREWAI_AGENT_TOKEN=[MASKED:#{mask_secret(agent_token, 4)}]"
  end
  log << "ENV_REDMINE_URL=#{redmine_url}" if redmine_url && !redmine_url.empty?
  # create a safe copy of payload for logging (redact query keys)
  safe_payload = payload.dup
  safe_payload[:attachments] = safe_payload[:attachments].map do |a|
    a2 = a.dup
    if a2[:url]
      a2[:url] = sanitize_url_for_log(a2[:url])
    end
    a2
  end
  log << "OUTGOING_PAYLOAD: #{safe_payload.to_json}"
  post_to_agent(agent_endpoint, agent_token, payload, log)
  end
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
ensure
  log << "PROCESS_COMPLETE_AT: #{Time.now}" 
end
begin
  tmp_path = '/tmp/process_rfps_out.txt'
  begin
    FileUtils.mkdir_p(File.dirname(tmp_path))
  rescue
  end
  File.write(tmp_path, log.join("\n"))
rescue => e
  # ignore
end
begin
  # also write to Redmine files dir (persisted volume) so host can inspect
  files_path = '/usr/src/redmine/files/crewai_process_rfps_out.txt'
  begin
    FileUtils.mkdir_p(File.dirname(files_path))
  rescue
  end
  File.write(files_path, log.join("\n"))
rescue => e
  # ignore
end
begin
  File.open(files_path, 'a') {|f| f.puts "LOG_FLUSHED_AT: #{Time.now}" }
rescue
end
begin
  puts log.join("\n")
rescue
  # stdout may be unavailable in some exec contexts
end
log = nil
