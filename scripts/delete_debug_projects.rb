# scripts/delete_debug_projects.rb
log = []
begin
  # match identifiers created by tests (rfp-...)
  by_ident = Project.where("identifier LIKE 'rfp-%'").to_a
  by_name = Project.where("name LIKE 'Project from RFP %'").to_a
  projects = (by_ident + by_name).uniq { |p| p.id }
  if projects.empty?
    log << "NO_DEBUG_PROJECTS_FOUND"
  else
    projects.each do |p|
      log << "DELETING_PROJECT: #{p.id}:#{p.name} identifier=#{p.identifier}"
      begin
        p.destroy
        log << "DELETED_PROJECT: #{p.id}"
      rescue => e
        log << "FAILED_DELETE: #{p.id}: #{e.class}: #{e.message}"
      end
    end
  end
rescue => e
  log << "FATAL_ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/delete_debug_projects_out.txt', log.join("\n"))
puts log.join("\n")
