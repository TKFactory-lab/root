['nobu','hide','yasu'].each do |l|
  u = User.find_by(login: l)
  if u
    pref = u.pref
    api = if u.respond_to?(:api_key) then u.api_key
          elsif u.respond_to?(:api_token) then u.api_token
          else u.read_attribute('api_key') rescue (u.read_attribute('api_token') rescue nil)
          end
    pref_no_self = pref.respond_to?(:no_self_notified) ? pref.no_self_notified : nil
    pref_mail = pref.respond_to?(:mail_notification) ? pref.mail_notification : nil
    puts "#{l}: id=#{u.id} admin=#{u.admin} api=#{api} no_self_notified=#{pref_no_self} mail_notification=#{pref_mail}"
  else
    puts "#{l}: missing"
  end
end
