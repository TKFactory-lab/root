#!/usr/bin/env ruby
# scripts/create_redmine_users.rb
# Run inside Redmine container via `bundle exec rails runner`.
# Creates nobu/hide/yasu users, sets nobu as admin, disables email notification,
# and sets API keys from environment variables if provided.

require 'securerandom'

users = [
  { login: 'nobu', firstname: 'Nobu', lastname: 'Oda', mail: 'nobu@example.com', pw_env: 'NOBU_PW', api_env: 'NOBUNAGA_API_KEY', admin: true },
  { login: 'hide', firstname: 'Hide', lastname: 'Toyotomi', mail: 'hide@example.com', pw_env: 'HIDE_PW', api_env: 'HIDE_API_KEY', admin: false },
  { login: 'yasu', firstname: 'Yasu', lastname: 'Tokugawa', mail: 'yasu@example.com', pw_env: 'YASU_PW', api_env: 'IEYASU_API_KEY', admin: false },
]

puts "Running Redmine user bootstrap (pid=#{Process.pid})"

users.each do |u|
  login = u[:login]
  puts "Checking: #{login}" 
  existing = User.find_by(login: login) rescue nil
  if existing
    puts "  exists: #{login} id=#{existing.id}"
    user = existing
  else
    password = ENV[u[:pw_env]] || SecureRandom.urlsafe_base64(9)
    user = User.new(
      login: login,
      firstname: u[:firstname],
      lastname: u[:lastname],
      mail: u[:mail]
    )
    user.password = password
    user.password_confirmation = password
    user.status = 1
    user.admin = !!u[:admin]
    if user.save
      puts "  created: #{login} id=#{user.id}"
    else
      puts "  failed to create #{login}: #{user.errors.full_messages.join(', ')}"
      next
    end
  end

  # Set API key/token if provided via ENV, otherwise ensure one exists.
  # Some Redmine versions expect Token objects; to be compatible we write
  # directly to DB using update_column for the underlying column when
  # necessary to avoid type-casting errors.
  desired_api = ENV[u[:api_env]]

  # Determine which column name to use (api_key or api_token)
  api_column = nil
  begin
    cols = user.class.column_names
    if cols.include?("api_key")
      api_column = "api_key"
    elsif cols.include?("api_token")
      api_column = "api_token"
    end
  rescue
    api_column = nil
  end

  # Attempt to locate a Token-like model when Redmine stores tokens separately
  token_model = nil
  begin
    if defined?(Token)
      token_model = Token
    elsif defined?(ApiToken)
      token_model = ApiToken
    else
      # find any AR model with "token" in the name and a user_id column
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

  # Helper to choose token value column on token_model
  find_token_value_column = lambda do |mdl|
    return nil unless mdl && mdl.respond_to?(:column_names)
    %w[value token plain_token key].each do |c|
      return c if mdl.column_names.include?(c)
    end
    mdl.column_names.find { |c| c =~ /token|value|key/i }
  end
  # (no debug prints in production)

  write_db_api = lambda do |usr, col, val|
    if col
      # update_column bypasses type casting/validation and writes raw value
      usr.update_column(col, val)
    elsif token_model
      tcol = find_token_value_column.call(token_model)
      existing = token_model.where(user_id: usr.id).first
      if existing
        if tcol
          existing.update_column(tcol, val)
        else
          # pick first non-id column to update
          colname = (existing.column_names - %w[id user_id created_at updated_at]).first
          existing.update_column(colname, val)
        end
      else
        attrs = { 'user_id' => usr.id }
        attrs[tcol || 'token'] = val
        token_model.create!(attrs)
      end
    else
      # fallback: try attribute writers (may raise)
      if usr.respond_to?(:api_key=)
        usr.api_key = val
        usr.save!
      elsif usr.respond_to?(:api_token=)
        usr.api_token = val
        usr.save!
      else
        raise "no writable api attribute found for user"
      end
    end
  end

  read_db_api = lambda do |usr, col|
    if col
      usr.read_attribute(col) rescue nil
    elsif token_model
      tcol = find_token_value_column.call(token_model)
      tok = token_model.where(user_id: usr.id).first
      if tok
        if tcol
          tok.read_attribute(tcol) rescue nil
        else
          tok.attributes.except('id', 'user_id', 'created_at', 'updated_at').values.first
        end
      else
        nil
      end
    else
      if usr.respond_to?(:api_key)
        usr.api_key
      elsif usr.respond_to?(:api_token)
        usr.api_token
      else
        nil
      end
    end
  end

  if desired_api && !desired_api.empty?
    begin
      write_db_api.call(user, api_column, desired_api)
      puts "  api key set from ENV for #{login}"
    rescue => e
      puts "  failed to set api key for #{login}: #{e.message}"
    end
  else
    existing_api = read_db_api.call(user, api_column)
    if existing_api.nil? || existing_api.to_s.empty?
      new_api = SecureRandom.hex(20)
      begin
        write_db_api.call(user, api_column, new_api)
        puts "  generated api key for #{login}"
      rescue => e
        puts "  failed to generate api key for #{login}: #{e.message}"
      end
    else
      puts "  api key exists for #{login}"
    end
  end

  # Disable email notifications for the user
  begin
    # UserPreference is available as user.pref
    pref = user.pref || UserPreference.new(:user => user)
    # Try common preference flags; Redmine versions vary
    if pref.respond_to?(:no_self_notified=)
      pref.no_self_notified = true
      pref.save!
      puts "  disabled self notifications for #{login} (no_self_notified)"
    elsif pref.respond_to?(:mail_notification=)
      pref.mail_notification = false
      pref.save!
      puts "  disabled mail_notification for #{login}"
    else
      # Fallback: try to set notify settings via custom prefs hash if available
      begin
        pref.save!
        puts "  saved preferences for #{login} (no specific flag changed)"
      rescue => e
        puts "  could not modify preferences for #{login}: #{e.message}"
      end
    end
  rescue => e
    puts "  preference change failed for #{login}: #{e.message}"
  end
end

puts "Bootstrap completed." 
