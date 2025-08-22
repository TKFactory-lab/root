# scripts/create_hourly_report.rb
log = []
begin
  log << "START: #{Time.now}"
  # Choose project: env PROJECT_IDENTIFIER or latest rfp-* project or template
  proj_ident = ENV['PROJECT_IDENTIFIER']
  project = if proj_ident && !proj_ident.empty?
              Project.find_by(identifier: proj_ident)
            else
              Project.where("identifier LIKE 'rfp-%'").order(id: :desc).first || Project.find_by(identifier: 'tkfactorylab-scrum-template')
            end
  raise "No project found (checked PROJECT_IDENTIFIER=#{proj_ident.inspect})" unless project
  log << "PROJECT: #{project.id}:#{project.identifier}"

  author_login = ENV['AUTHOR'] || 'nobu'
  author = User.find_by(login: author_login)
  raise "No author user found #{author_login}" unless author
  log << "AUTHOR: #{author.id}:#{author.login}"

  tracker = Tracker.find_by(name: 'Report')
  raise "No Report tracker found" unless tracker

  # ensure project accepts Report tracker
  unless project.trackers.map(&:id).include?(tracker.id)
    project.trackers = (project.trackers | [tracker])
    project.save!
    log << "ADDED_TRACKER: #{tracker.name} -> #{project.identifier}"
  end

  # ensure priority exists
  if IssuePriority.count == 0
    %w[Low Normal High].each_with_index do |pn, i|
      IssuePriority.create!(name: pn, position: i+1)
    end
    log << "CREATED_DEFAULT_PRIORITIES"
  end
  priority = IssuePriority.order(:position).first
  raise "No IssuePriority available" unless priority

  status_open = IssueStatus.find_by(name: 'Open') || IssueStatus.order(:position).first

  ts = Time.now
  subject = ENV['SUBJECT'] || "Hourly report #{ts.strftime('%Y-%m-%d %H:%M')}"
  body = ENV['BODY'] || "Progress summary:\n- Progress:\n- Blockers:\n- Mitigation:\n\nGenerated at #{ts}\n"

  issue = Issue.create!(project: project, tracker: tracker, subject: subject, description: body, author: author, status: status_open, priority: priority)
  log << "CREATED_REPORT: #{issue.id} project=#{project.identifier} author=#{author.login} subject=#{subject}"
  # add ktakada (or configured WATCHER) as watcher to ensure notification
  watcher_login = ENV['WATCHER'] || 'ktakada'
  watcher = User.find_by(login: watcher_login)
  if watcher
    begin
      unless issue.watchers.map(&:user_id).include?(watcher.id)
        Watcher.create!(user_id: watcher.id, watchable_id: issue.id, watchable_type: 'Issue')
        log << "ADDED_WATCHER: #{watcher.login} -> issue #{issue.id}"
      else
        log << "WATCHER_EXISTS: #{watcher.login} already watching issue #{issue.id}"
      end
    rescue => e
      log << "FAILED_ADD_WATCHER: #{e.class}:#{e.message}"
    end
  else
    log << "NO_WATCHER_USER: #{watcher_login}"
  end
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/create_hourly_report_out.txt', log.join("\n"))
puts log.join("\n")
