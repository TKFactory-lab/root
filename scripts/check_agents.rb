#!/usr/bin/env ruby
# scripts/check_agents.rb
require File.expand_path('../config/environment', __dir__)
require 'json'

out = {}
['nobu','hide','yasu'].each do |login|
  u = User.find_by(login: login)
  out[login] = u ? {exists: true, id: u.id} : {exists: false}
end

# watchers for issue 13
issue_id = 13
begin
  watchers = Watcher.where(watchable_type: 'Issue', watchable_id: issue_id).map {|w| w.user.login }
rescue => e
  watchers = "ERROR: #{e.class}: #{e.message}"
end

# process log
log_path = '/usr/src/redmine/files/crewai_process_rfps_out.txt'
log = if File.exist?(log_path)
  File.read(log_path)
else
  "MISSING #{log_path}"
end

puts JSON.pretty_generate({users: out, issue_watchers_issue_13: watchers, process_log_head: log[0,4000]})
