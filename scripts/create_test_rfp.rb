#!/usr/bin/env ruby
# scripts/create_test_rfp.rb
require File.expand_path('../config/environment', __dir__)

p = Project.find_by(identifier: 'crewai-rfps')
t = Tracker.find_by(name: 'RFP')
u = User.find_by(login: 'ktakada')
s = IssueStatus.find_by(name: 'Submitted')
i = Issue.create!(project: p, tracker: t, subject: 'TEST RFP - Auto project creation', description: 'Please start project X', author: u, status_id: s.id)
puts "CREATED_TEST_RFP=#{i.id}"
