#!/usr/bin/env ruby
# scripts/ensure_rfp_workflow.rb
# Idempotent script to ensure the minimal Redmine objects exist for the RFP -> project flow
require 'json'
require 'securerandom'

out = {}
begin
  # Tracker
  tracker = Tracker.find_by(name: 'RFP')
  if tracker
    out['tracker_exists'] = tracker.id
  else
    tracker = Tracker.create!(name: 'RFP')
    out['tracker_created'] = tracker.id
  end

  # Statuses
  submitted = IssueStatus.find_or_create_by!(name: 'Submitted')
  accepted = IssueStatus.find_or_create_by!(name: 'Accepted')
  out['statuses'] = [submitted.name, accepted.name]

  # Intake project
  intake = Project.find_by(identifier: 'crewai-rfps')
  unless intake
    intake = Project.new(name: 'CrewAI RFP Intake', identifier: 'crewai-rfps')
    intake.is_public = false
    intake.trackers = [tracker]
    intake.save!
    out['intake_created'] = intake.id
  else
    out['intake_exists'] = intake.id
  end

  # Template project (minimal)
  template = Project.find_by(identifier: 'tkfactorylab-scrum-template')
  unless template
    template = Project.new(name: 'tkfactorylab-scrum-template', identifier: 'tkfactorylab-scrum-template')
    template.is_public = false
    template.trackers = Tracker.all
    template.save!
    out['template_created'] = template.id
  else
    out['template_exists'] = template.id
  end

  # nobu user
  nobu = User.find_by(login: 'nobu')
  unless nobu
    nobu = User.new(login: 'nobu', firstname: 'Nobu', lastname: 'User', mail: 'nobu@example.invalid', language: 'en')
    pwd = SecureRandom.hex(12)
    nobu.password = pwd
    nobu.password_confirmation = pwd
    nobu.mail_notification = 'none'
    nobu.save!
    out['nobu_created'] = { 'id' => nobu.id, 'mail' => nobu.mail }
  else
    out['nobu_exists'] = nobu.id
  end

  # Project Lead role
  pl = Role.find_by(name: 'Project Lead')
  unless pl
    pl = Role.create!(name: 'Project Lead')
    out['role_created'] = pl.id
  else
    out['role_exists'] = pl.id
  end

  # Add nobu to intake
  if intake && nobu
    unless Member.exists?(project_id: intake.id, user_id: nobu.id)
      Member.create!(project_id: intake.id, user_id: nobu.id, role_ids: [pl.id])
      out['nobu_added_to_intake'] = true
    else
      out['nobu_member_of_intake'] = true
    end
  end

  # env
  out['env'] = { 'CREWAI_AGENT_WEBHOOK' => ENV['CREWAI_AGENT_WEBHOOK'], 'CREWAI_AGENT_TOKEN' => ENV['CREWAI_AGENT_TOKEN'], 'REDMINE_URL' => ENV['REDMINE_URL'] }

  # RFP count
  if intake
    out['rfp_count'] = intake.issues.where(tracker: tracker).count
  else
    out['rfp_count'] = 0
  end
rescue => e
  out['error'] = "#{e.class}: #{e.message}"
  out['backtrace'] = e.backtrace
end

File.write('/tmp/ensure_rfp_workflow_out.txt', JSON.generate(out))
puts JSON.pretty_generate(out)
