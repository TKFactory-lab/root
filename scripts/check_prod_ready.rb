# scripts/check_prod_ready.rb
out = []
# project
p = Project.find_by(identifier: 'crewai-rfps')
if p
  out << "PROJECT=found id=#{p.id} name=#{p.name} identifier=#{p.identifier}"
  members = p.members.map{|m| "#{m.user.login}:#{m.roles.map(&:name).join('|')}"}
  out << "PROJECT_MEMBERS=#{members.join(',')}"
else
  out << "PROJECT=missing"
end
# tracker
out << "TRACKER_RFP=#{!!Tracker.find_by(name: 'RFP')}"
# users
['ktakada','nobu'].each do |login|
  u = User.find_by(login: login)
  out << "USER_#{login}=#{u ? "id=#{u.id} mail=#{u.mail}" : 'missing'}"
end
# scripts
out << "SCRIPT_process_rfps=#{File.exist?('/usr/src/redmine/scripts/process_rfps.rb')}"
out << "SCRIPT_run_hourly_report_cron=#{File.exist?('/usr/src/redmine/scripts/run_hourly_report_cron.sh')}"
# settings (attachment-related keys)
begin
  keys = Setting.to_hash.keys.select{|k| k.to_s =~ /attach|file|storage|max/}
  out << "SETTING_KEYS_ATTACH_MATCH=#{keys.join(',')}"
rescue => e
  out << "SETTING_READ_ERROR=#{e.message}"
end
# output
puts out.join("\n")
