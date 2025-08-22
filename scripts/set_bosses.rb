# scripts/set_bosses.rb
# Create a User custom field 'Boss' and set boss usernames for the agents.
begin
  field = UserCustomField.find_by(name: 'Boss')
  unless field
    field = UserCustomField.create!(name: 'Boss', field_format: 'string', is_for_all: true, is_required: false, editable: true, visible: true)
    puts "Created UserCustomField 'Boss' id=#{field.id}"
  else
    puts "UserCustomField 'Boss' exists id=#{field.id}"
  end
rescue => e
  puts "Failed to ensure UserCustomField: #{e.class}: #{e.message}"
  field = nil
end

mapping = {
  'nobu' => 'ktakada',
  'hide' => 'nobu',
  'yasu' => 'nobu'
}

File.open('/tmp/set_boss_results.txt','w') do |f|
  if field.nil?
    f.puts "ERROR: no Boss custom field available"
  else
    mapping.each do |u_login, boss_login|
      begin
        u = User.find_by(login: u_login)
        b = User.find_by(login: boss_login)
        if u.nil?
          f.puts "#{u_login}: USER MISSING"
          next
        end
        if b.nil?
          f.puts "#{u_login}: BOSS #{boss_login} MISSING"
        end
        cv = CustomValue.where(customized_type: 'User', customized_id: u.id, custom_field_id: field.id).first_or_initialize
        cv.value = boss_login
        cv.save!
        f.puts "#{u_login}: boss set to #{boss_login} (custom_field_id=#{field.id})"
      rescue => e
        f.puts "#{u_login}: failed to set boss: #{e.class}: #{e.message}"
      end
    end

    # verification
    f.puts "--verification--"
    mapping.keys.each do |l|
      u = User.find_by(login: l)
      next unless u
      val = u.custom_value_for(field) rescue nil
      f.puts "#{l}: boss=#{val}"
    end
  end
end
