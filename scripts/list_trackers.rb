# scripts/list_trackers.rb
# Writes tracker and template project tracker info to /tmp/list_trackers_out.txt
log = []
begin
  log << "TRACKER_COUNT: #{Tracker.count}"
  Tracker.all.each do |t|
    log << "TRACKER: #{t.id}: #{t.name}"
  end
  log << "TRACKER_COLUMNS: #{Tracker.column_names.join(', ')}"
  p = Project.find_by(identifier: 'tkfactorylab-scrum-template')
  if p
    log << "TEMPLATE_PROJECT: #{p.id}: #{p.name}"
    log << "PROJECT_TRACKERS: #{p.trackers.map{|t| t&.name}.join(', ')}"
  else
    log << 'TEMPLATE_PROJECT: not found'
  end
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log << e.backtrace.join("\n")
end
File.open('/tmp/list_trackers_out.txt','w') do |f|
  log.each{|l| f.puts l }
end
