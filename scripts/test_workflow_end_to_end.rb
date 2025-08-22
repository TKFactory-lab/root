# scripts/test_workflow_end_to_end.rb
log = []
begin
  log << "START_TEST: #{Time.now}"
  p_template = Project.find_by(identifier: 'tkfactorylab-scrum-template')
  kt = User.find_by(login: 'ktakada')
  nb = User.find_by(login: 'nobu')
  raise 'missing template or users' unless p_template && kt && nb
  log << "FOUND_TEMPLATE: #{p_template.id}:#{p_template.name}"

  # RFP flow
  rfp_tracker = Tracker.find_by(name: 'RFP')
  submitted = IssueStatus.find_by(name: 'Submitted')
  accepted = IssueStatus.find_by(name: 'Accepted')
  raise 'missing rfp tracker or statuses' unless rfp_tracker && submitted && accepted
  # ensure the template project allows the RFP tracker
  unless p_template.trackers.map(&:id).include?(rfp_tracker.id)
    p_template.trackers = (p_template.trackers | [rfp_tracker])
    p_template.save!
    log << "ADDED_TRACKER_TO_TEMPLATE: #{rfp_tracker.name} -> #{p_template.name}"
  end

  # ensure a priority exists; create defaults if none
  if IssuePriority.count == 0
    %w[Low Normal High].each_with_index do |pn, i|
      IssuePriority.create!(name: pn, position: i+1)
    end
    log << "CREATED_DEFAULT_PRIORITIES: Low, Normal, High"
  end
  priority = IssuePriority.order(:position).first
  raise 'no IssuePriority found' unless priority

  rfp = Issue.create!(project: p_template, tracker: rfp_tracker, subject: 'TEST RFP from ktakada', description: 'Please start this project', author: kt, status_id: submitted.id, priority_id: priority.id)
  log << "CREATED_RFP: #{rfp.id} status=#{rfp.status.name} author=#{rfp.author.login}"

  # nobu accepts (reload after journaling to avoid optimistic locking issues)
  rfp.init_journal(nb, 'Accepting RFP by nobu')
  rfp.reload
  rfp.status_id = accepted.id
  rfp.save!
  log << "RFP_ACCEPTED: #{rfp.id} status=#{rfp.reload.status.name}"

  # Create project from template
  new_proj = Project.new(name: "Project from RFP #{rfp.id} - #{Time.now.strftime('%Y%m%d%H%M')}", identifier: "rfp-#{rfp.id}-#{Time.now.to_i}", description: 'Auto-created from RFP')
  new_proj.is_public = false
  new_proj.trackers = p_template.trackers
  new_proj.enabled_module_names = p_template.enabled_module_names
  new_proj.save!
  log << "CREATED_PROJECT: #{new_proj.id} identifier=#{new_proj.identifier}"

  # ensure new project includes Q&A and Report trackers (they may not be in template)
  qa_tracker = Tracker.find_by(name: 'Q&A')
  report_tracker = Tracker.find_by(name: 'Report')
  missing = []
  missing << qa_tracker if qa_tracker && !new_proj.trackers.map(&:id).include?(qa_tracker.id)
  missing << report_tracker if report_tracker && !new_proj.trackers.map(&:id).include?(report_tracker.id)
  if missing.any?
    new_proj.trackers = (new_proj.trackers | missing)
    new_proj.save!
    log << "ADDED_MISSING_TRACKERS_TO_NEW_PROJECT: #{missing.map(&:name).join(', ')}"
  end

  # copy categories
  p_template.issue_categories.each do |c|
    new_proj.issue_categories.create!(name: c.name)
  end
  log << "COPIED_CATEGORIES: #{new_proj.issue_categories.map(&:name).join(', ')}"

  # copy versions (simple copy)
  p_template.versions.each do |v|
    new_proj.versions.create!(name: v.name, due_date: v.due_date, status: v.status)
  end
  log << "COPIED_VERSIONS: #{new_proj.versions.map(&:name).join(', ')}"

  # assign members: nobu as Project Lead, ktakada as Client
  pl_role = Role.find_by(name: 'Project Lead')
  client_role = Role.find_by(name: 'Client')
  if pl_role && client_role
    Member.create!(project_id: new_proj.id, user_id: nb.id, role_ids: [pl_role.id])
    Member.create!(project_id: new_proj.id, user_id: kt.id, role_ids: [client_role.id])
    log << "ADDED_MEMBERS: nobu(#{nb.id}) as Project Lead, ktakada(#{kt.id}) as Client"
  else
    log << "MISSING_ROLES: pl=#{pl_role.inspect} client=#{client_role.inspect}"
  end

  # Q&A flow
  qa_tracker = Tracker.find_by(name: 'Q&A')
  open_s = IssueStatus.find_by(name: 'Open')
  answered_s = IssueStatus.find_by(name: 'Answered')
  closed_s = IssueStatus.find_by(name: 'Closed')
  raise 'missing qa objects' unless qa_tracker && open_s && answered_s && closed_s

  qa = Issue.create!(project: new_proj, tracker: qa_tracker, subject: 'TEST Q&A from ktakada', description: 'Question: clarify API', author: kt, status_id: open_s.id, priority_id: priority.id)
  log << "CREATED_QA: #{qa.id} status=#{qa.status.name}"

  # nobu answers (reload after journaling)
  qa.init_journal(nb, 'Answer: The API uses X')
  qa.reload
  qa.status_id = answered_s.id
  qa.save!
  log << "QA_ANSWERED: #{qa.id} status=#{qa.reload.status.name} by=#{nb.login}"

  # ktakada closes (reload after journaling)
  qa.init_journal(kt, 'Thanks, closing')
  qa.reload
  qa.status_id = closed_s.id
  qa.save!
  log << "QA_CLOSED: #{qa.id} status=#{qa.reload.status.name} by=#{kt.login}"

  # Report flow
  report_tracker = Tracker.find_by(name: 'Report')
  open_r = IssueStatus.find_by(name: 'Open')
  ack = IssueStatus.find_by(name: 'Acknowledged')
  raise 'missing report objects' unless report_tracker && open_r && ack

  rep = Issue.create!(project: new_proj, tracker: report_tracker, subject: 'Hourly report sample', description: 'Progress OK', author: nb, status_id: open_r.id, priority_id: priority.id)
  log << "CREATED_REPORT: #{rep.id} status=#{rep.status.name} by=#{nb.login}"

  # ktakada acknowledges (reload after journaling)
  rep.init_journal(kt, 'Acknowledged')
  rep.reload
  rep.status_id = ack.id
  rep.save!
  log << "REPORT_ACK: #{rep.id} status=#{rep.reload.status.name} by=#{kt.login}"

  log << "TEST_COMPLETED: #{Time.now}"
rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/test_workflow_out.txt', log.join("\n"))
puts log.join("\n")
