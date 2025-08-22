# scripts/ensure_trackers.rb
log = []
begin
  log << "TRACKER_COUNT_BEFORE: #{Tracker.count}"
  Tracker.all.each { |t| log << "TRACKER_BEFORE: #{t.id}: #{t.name}" }
  %w[Epic Story Task Bug Improvement].each do |name|
    t = Tracker.where(name: name).first_or_create
    if t.persisted?
      log << "CREATED_OR_EXISTS: #{t.id}: #{t.name}"
    else
      log << "FAILED_CREATE: #{name} errors=#{t.errors.full_messages.join('; ')}"
    end
  end
  log << "TRACKER_COUNT_AFTER: #{Tracker.count}"
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log << e.backtrace.join("\n")
end
# write to /tmp and also print to stdout
File.write('/tmp/ensure_trackers_out.txt', log.join("\n"))
puts log.join("\n")
