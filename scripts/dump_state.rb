#!/usr/bin/env ruby
# scripts/dump_state.rb
require 'json'
out = {}
begin
  out['time'] = Time.now
  out['ruby'] = `ruby -v`.strip
  out['rails'] = `rails -v`.strip
  out['intake'] = (p = Project.find_by(identifier: 'crewai-rfps')) ? {id: p.id, name: p.name} : nil
  out['template'] = (t = Project.find_by(identifier: 'tkfactorylab-scrum-template')) ? {id: t.id, name: t.name} : nil
  out['tracker_rfp'] = !!Tracker.find_by(name: 'RFP')
  out['status_submitted'] = !!IssueStatus.find_by(name: 'Submitted')
  out['status_accepted'] = !!IssueStatus.find_by(name: 'Accepted')
  out['nobu'] = (u = User.find_by(login: 'nobu')) ? {id: u.id, login: u.login, mail: u.mail} : nil
  out['roles'] = Role.all.map{|r| {id: r.id, name: r.name}}
  out['project_lead_role'] = Role.find_by(name: 'Project Lead') ? true : false
  out['env'] = {CREWAI_AGENT_WEBHOOK: ENV['CREWAI_AGENT_WEBHOOK'], CREWAI_AGENT_TOKEN: ENV['CREWAI_AGENT_TOKEN'] ? 'SET' : nil, REDMINE_URL: ENV['REDMINE_URL']}
  if out['intake']
    tracker = Tracker.find_by(name: 'RFP')
    out['rfp_count'] = tracker ? Project.find_by(identifier: 'crewai-rfps').issues.where(tracker: tracker).count : 0
    out['rfps'] = []
    if tracker
      Project.find_by(identifier: 'crewai-rfps').issues.where(tracker: tracker).limit(10).each do |i|
        out['rfps'] << {id: i.id, subject: i.subject, status: i.status&.name, author: i.author&.login}
      end
    end
  else
    out['rfp_count'] = 0
  end
rescue => e
  out['error'] = {class: e.class.to_s, message: e.message, backtrace: e.backtrace[0,20]}
end
File.write('/tmp/full_debug.json', JSON.pretty_generate(out))
puts File.read('/tmp/full_debug.json')
