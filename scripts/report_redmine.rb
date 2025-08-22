# scripts/report_redmine.rb
log = []
begin
  log << "ENV: #{Rails.env}"
  # Trackers
  log << "TRACKER_COUNT: #{Tracker.count}"
  Tracker.all.each { |t| log << "TRACKER: #{t.id}: #{t.name} pos=#{t.position} default_status=#{t.default_status_id}" }
  # Roles and permissions
  begin
    Role.all.each do |r|
      perms = (r.permissions || []).map(&:name) rescue []
      log << "ROLE: #{r.id}: #{r.name} permissions=#{perms.join(', ')}"
    end
  rescue => e
    log << "ROLE LIST ERROR: #{e.class}: #{e.message}"
  end
  # Template project
  p = Project.find_by(identifier: 'tkfactorylab-scrum-template') || Project.find_by(name: 'TKFactoryLAB Scrum Template')
  if p
    log << "TEMPLATE_PROJECT: #{p.id}: #{p.name}"
    log << "PROJECT_TRACKERS: #{p.trackers.map{|t| t.name}.join(', ')}"
    log << "PROJECT_CATEGORIES: #{p.issue_categories.map{|c| c.name}.join(', ')}"
    log << "PROJECT_VERSIONS: #{p.versions.map{|v| v.name}.join(', ')}"
    log << "PROJECT_MEMBERS: #{p.members.map{|m| "#{m.user.id}:#{m.user.login}:#{m.roles.map(&:name).join('|')}"}.join('; ')}"
  else
    log << "TEMPLATE_PROJECT: not found"
  end
  # Users of interest
  ['nobu','hide','yasu','ktakada'].each do |login|
    u = User.find_by(login: login)
    if u
      tv = Token.where(user_id: u.id).first
      token = tv ? tv.value : (u.api_token if u.respond_to?(:api_token)) rescue nil
      cf = {}
      if CustomField.exists?
        CustomField.where(field_format: 'string').each do |cf_def|
          val = u.custom_values.detect{|cv| cv.custom_field_id == cf_def.id} rescue nil
          cf[cf_def.name] = val ? val.value : nil
        end
      end
      log << "USER: #{u.id}:#{u.login} mail=#{u.mail} token=#{token} custom=#{cf.inspect}"
    else
      log << "USER: not found: #{login}"
    end
  end
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log << e.backtrace.join("\n")
end
File.open('/tmp/report_out.txt','w') { |f| log.each{|l| f.puts l } }
puts log.join("\n")
