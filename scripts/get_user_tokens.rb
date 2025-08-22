#!/usr/bin/env ruby
# scripts/get_user_tokens.rb
# Prints token information for given users (works with api_key/api_token columns or Token-like models)
users = %w[nobu hide yasu]

token_model = nil
begin
  if defined?(Token)
    token_model = Token
  elsif defined?(ApiToken)
    token_model = ApiToken
  else
    ActiveRecord::Base.descendants.each do |c|
      next unless c.respond_to?(:column_names)
      if c.name =~ /token/i && c.column_names.include?("user_id")
        token_model = c
        break
      end
    end
  end
rescue => _e
  token_model = nil
end

find_token_value_column = lambda do |mdl|
  return nil unless mdl && mdl.respond_to?(:column_names)
  %w[value token plain_token key].each do |c|
    return c if mdl.column_names.include?(c)
  end
  mdl.column_names.find { |c| c =~ /token|value|key/i }
end

puts "get_user_tokens (pid=#{Process.pid})"
puts "detected token_model=#{token_model ? token_model.name : nil}"
puts "detected token_value_col=#{find_token_value_column.call(token_model).inspect}"

users.each do |login|
  u = User.find_by(login: login) rescue nil
  if u.nil?
    puts "#{login}: MISSING"
    next
  end
  puts "#{login}: id=#{u.id} admin=#{!!u.admin}"
  # check user columns
  begin
    %w[api_key api_token].each do |col|
      if u.respond_to?(col) && (val = u.send(col)) && !val.to_s.empty?
        puts "  user.#{col}=#{val}"
      elsif u.respond_to?(:read_attribute) && (u.class.column_names.include?(col))
        val2 = u.read_attribute(col) rescue nil
        puts "  user.#{col}=#{val2}" if val2 && !val2.to_s.empty?
      end
    end
  rescue => _e
  end

  # check token model
  if token_model
    tcol = find_token_value_column.call(token_model)
    token_model.where(user_id: u.id).each do |t|
      attrs = t.attributes.reject{|k,_| %w[created_at updated_at].include?(k)}
      display = {}
      display['id'] = attrs['id'] if attrs['id']
      display['user_id'] = attrs['user_id'] if attrs['user_id']
      if tcol && attrs.key?(tcol)
        display[tcol] = attrs[tcol]
      else
        # show first non-id field
        kv = attrs.reject{|k,_| %w[id user_id].include?(k)}.first
        display[kv.first] = kv.last if kv
      end
      puts "  token_record: #{display.inspect}"
    end
  end
end
