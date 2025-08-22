# dump_tokens.rb
begin
  if defined?(Token)
    puts "Token model: #{Token.name}"
    Token.all.each do |t|
      puts t.attributes.except('created_at','updated_at').inspect
    end
    [5,6,7].each do |uid|
      puts "Tokens for uid=#{uid}:"
      Token.where(user_id: uid).each do |t|
        puts t.attributes.except('created_at','updated_at').inspect
      end
    end
  else
    puts 'Token class not defined'
  end
rescue => e
  puts "error: #{e.class} #{e.message}"
end
