# scripts/create_trackers_with_default.rb
log = []
begin
  default = IssueStatus.find_by(name: 'New') || IssueStatus.first
  raise "no IssueStatus found" unless default
  log << "USING_DEFAULT_STATUS: #{default.id}:#{default.name}"
  %w[Epic Story Task Bug Improvement].each do |name|
    t = Tracker.where(name: name).first_or_initialize
    t.default_status_id = default.id
    t.position ||= (Tracker.maximum(:position) || 0) + 1
    if t.new_record?
      t.save!
      log << "CREATED: #{t.id}:#{t.name} default_status=#{default.name}"
    else
      if t.changed?
        t.save!
        log << "UPDATED: #{t.id}:#{t.name} default_status=#{default.name}"
      else
        log << "EXISTS: #{t.id}:#{t.name} default_status=#{t.default_status_id}"
      end
    end
  end
  log << "TRACKER_COUNT_FINAL: #{Tracker.count}"
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/create_trackers_with_default_out.txt', log.join("\n"))
puts log.join("\n")
