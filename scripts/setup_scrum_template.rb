# scripts/setup_scrum_template.rb
# Create a Scrum template: trackers, statuses, roles, categories, example sprint version, and a template project.
log = []
begin
  # Trackers
  tracker_names = %w[Epic Story Task Bug Improvement]
  trackers = tracker_names.map do |n|
    t = Tracker.where(name: n).first_or_initialize
    begin
      if t.new_record?
        t.save!
        log << "created tracker: #{n} id=#{t.id}"
      else
        log << "tracker exists: #{n} id=#{t.id}"
      end
    rescue => e
      log << "FAILED creating tracker #{n}: #{e.class}: #{e.message}"
    end
    t
  end

  # Ensure trackers are persisted and reload canonical objects
  trackers = tracker_names.map do |n|
    tt = Tracker.find_by(name: n)
    unless tt
      log << "ERROR: tracker #{n} could not be found after save"
    end
    tt
  end

  # Issue statuses
  statuses = [
    ['New', false],
    ['Backlog', false],
    ['Selected for Sprint', false],
    ['ToDo', false],
    ['In Progress', false],
    ['Review / QA', false],
    ['Done', true],
    ['Rejected', false]
  ]
  statuses.each_with_index do |(name, closed), idx|
    s = IssueStatus.where(name: name).first_or_initialize
    begin
      s.is_closed = closed
      s.position = idx+1
      s.save!
      log << "ensured status: #{name} id=#{s.id} closed=#{s.is_closed}"
    rescue => e
      log << "FAILED ensuring status #{name}: #{e.class}: #{e.message}"
    end
  end

  # Roles
  role_defs = {
    'Product Owner' => ['add_issues','edit_issues','manage_versions','manage_categories'],
    'Scrum Master' => ['add_issues','edit_issues','manage_boards','save_queries'],
    'Developer' => ['add_issues','edit_issues','log_time','edit_own_issues'],
    'QA' => ['add_issues','edit_issues','resolve_issues'],
    'Stakeholder' => []
  }
  role_defs.each do |rname, perms|
    begin
      r = Role.where(name: rname).first_or_create
      log << "ensured role: #{rname} id=#{r.id}"
    rescue => e
      log << "FAILED ensuring role #{rname}: #{e.class}: #{e.message}"
    end
    # Do not modify permissions automatically here to avoid unexpected side effects.
  end

  # Create template project
  proj_identifier = 'tkfactorylab-scrum-template'
  proj_name = 'TKFactoryLAB Scrum Template'
  p = Project.find_by(identifier: proj_identifier) || Project.find_by(name: proj_name)
  if p.nil?
    begin
      # Create and save the project first without trackers to avoid validation errors
      p = Project.new(name: proj_name, identifier: proj_identifier, description: 'Template project for Scrum (do not use directly).')
      p.is_public = false
      p.save!
      log << "created project placeholder: #{p.name} id=#{p.id}"
    rescue => e
      log << "FAILED creating project placeholder #{proj_name}: #{e.class}: #{e.message}"
    end
  else
    log << "project exists: #{p.name} id=#{p.id} (using existing project)"
  end

  # If we have a saved project, associate trackers and save again
  if p && p.persisted?
    begin
      real_trackers = trackers.compact
      p.trackers = (p.trackers | real_trackers)
      p.save!
      log << "project trackers assigned: #{p.name} id=#{p.id}, trackers=#{real_trackers.map(&:name).join(', ')}"
    rescue => e
      log << "FAILED assigning trackers to project #{p&.name}: #{e.class}: #{e.message}"
    end
  else
    log << "SKIPPING tracker association because project is not persisted"
  end

  # Categories
  cat_names = %w[UI/UX Frontend Backend Infra Test Docs]
  cat_names.each do |cn|
    begin
      ic = p.issue_categories.where(name: cn).first_or_create
      log << "ensured category #{cn} id=#{ic.id}"
    rescue => e
      log << "FAILED ensuring category #{cn}: #{e.class}: #{e.message}"
    end
  end

  # Example sprint/version
  sprint_name = "Sprint Example - #{Date.today.strftime('%Y-%m-%d')}"
  begin
    v = p.versions.where(name: sprint_name).first_or_initialize
    v.status = 'open'
    v.due_date = Date.today + 14
    v.save!
    log << "ensured version: #{v.name} id=#{v.id}"
  rescue => e
    log << "FAILED ensuring version #{sprint_name}: #{e.class}: #{e.message}"
  end

  # Optional: add standard trackers to project (already set)
  # Save summary
  log << "Scrum template setup completed"
rescue => e
  log << "ERROR: #{e.class}: #{e.message}\n#{e.backtrace.join('\n')}"
end

File.open('/tmp/scrum_setup_out.txt','w') do |f|
  log.each{|l| f.puts l}
end
