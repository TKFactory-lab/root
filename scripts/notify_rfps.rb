# scripts/notify_rfps.rb
# Find Submitted RFPs in crewai-rfps project that have not been notified, notify nobu via Slack/Webhook
require 'net/http'
require 'uri'
require 'json'

log = []
begin
  intake = Project.find_by(identifier: 'crewai-rfps')
  raise 'intake missing' unless intake
  submitted = IssueStatus.find_by(name: 'Submitted')
  raise 'Submitted status missing' unless submitted

  nobu = User.find_by(login: 'nobu')
  unless nobu
    log << 'USER nobu missing'
  end

  webhook = ENV['SLACK_WEBHOOK_URL'] || ENV['CREWAI_AGENT_WEBHOOK']
  token = ENV['SLACK_WEBHOOK_TOKEN'] || ENV['CREWAI_AGENT_TOKEN']
  redmine_url = ENV['REDMINE_URL'] || ''
  api_key = ENV['REDMINE_API_KEY'] || ''

  intake.issues.where(tracker: Tracker.find_by(name: 'RFP'), status_id: submitted.id).each do |rfp|
    # skip if already notified: check journals for marker
    already = rfp.journals.any? { |j| j.notes && j.notes.include?('NOTIFIED_BY_BOT') }
    if already
      log << "SKIP_ALREADY_NOTIFIED: #{rfp.id}"
      next
    end

    log << "NOTIFYING_RFP: #{rfp.id} #{rfp.subject}"

    # prepare payload
    attachments = rfp.attachments.map { |a| { filename: a.filename, url: (redmine_url.empty? ? nil : "#{redmine_url}/attachments/download/#{a.id}?key=#{api_key}") } }
    payload = {
      text: "RFP ##{rfp.id} created: #{rfp.subject}\n#{redmine_url.empty? ? '' : "#{redmine_url}/issues/#{rfp.id}"}",
      rfp: { id: rfp.id, subject: rfp.subject, author: (rfp.author && rfp.author.login), attachments: attachments }
    }

    sent = false
    if webhook && !webhook.empty?
      begin
        uri = URI.parse(webhook)
        req = Net::HTTP::Post.new(uri)
        req['Content-Type'] = 'application/json'
        req['Authorization'] = "Bearer #{token}" if token && !token.empty?
        req.body = payload.to_json
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          res = http.request(req)
          log << "WEBHOOK_RESP: #{res.code} #{res.message} for rfp #{rfp.id}"
          sent = res.code.start_with?('2')
        end
      rescue => ex
        log << "WEBHOOK_ERROR: #{ex.class}: #{ex.message} for rfp #{rfp.id}"
      end
    end

    # fallback: add nobu as watcher and add a journal note
    begin
      if !sent && nobu
        # add nobu as watcher if not already
        unless rfp.watchers.map(&:user).map(&:login).include?('nobu')
          rfp.watchers << Watcher.create!(user: nobu)
          log << "ADDED_WATCHER_NOBU: #{rfp.id}"
        end
        rfp.init_journal(nobu, "NOTIFIED_BY_BOT: added watcher nobu; no webhook")
        rfp.save!
        log << "JOURNAL_ADDED_NOTIFY: #{rfp.id}"
      elsif sent
        # mark notified in journal
        rfp.init_journal(nobu || User.anonymous, "NOTIFIED_BY_BOT: webhook sent")
        rfp.save!
        log << "JOURNAL_ADDED_WEBHOOK: #{rfp.id}"
      end
    rescue => ex
      log << "JOURNAL_ERROR: #{ex.class}: #{ex.message} for rfp #{rfp.id}"
    end
  end
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/notify_rfps_out.txt', log.join("\n"))
puts log.join("\n")
