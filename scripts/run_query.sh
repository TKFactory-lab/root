#!/bin/bash
# scripts/run_query.sh - run a rails runner inside the container to print JSON info
cd /usr/src/redmine || exit 1
bundle exec rails runner -e production 'require "json"; puts JSON.pretty_generate({users: {nobu: (u=User.find_by(login:"nobu"); u ? {exists:true,id:u.id} : {exists:false}), hide: (u=User.find_by(login:"hide"); u ? {exists:true,id:u.id} : {exists:false}), yasu: (u=User.find_by(login:"yasu"); u ? {exists:true,id:u.id} : {exists:false})}, issue13_watchers: (Watcher.where(watchable_type:"Issue", watchable_id:13).map{|w| begin; w.user.login; rescue; nil; end.compact), process_log_head: (File.exist?("/usr/src/redmine/files/crewai_process_rfps_out.txt") ? File.read("/usr/src/redmine/files/crewai_process_rfps_out.txt")[0,4000] : nil)})'
