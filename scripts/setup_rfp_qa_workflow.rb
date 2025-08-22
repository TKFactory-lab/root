# scripts/setup_rfp_qa_workflow.rb
# Adds trackers (RFP, Q&A, Report), statuses, roles (Client, Project Lead), and basic workflow permissions
log = []
begin
  log << "START: #{Time.now}"
  # ensure default status exists
  default = IssueStatus.find_by(name: 'New') || IssueStatus.first
  raise "No IssueStatus found" unless default
  log << "USING_DEFAULT_STATUS: #{default.id}:#{default.name}"

  # Trackers
  ['RFP','Q&A','Report'].each do |tname|
    t = Tracker.where(name: tname).first_or_initialize
    t.default_status_id = default.id
    t.position ||= (Tracker.maximum(:position) || 0) + 1
    if t.new_record?
      t.save!
      log << "CREATED_TRACKER: #{t.id}:#{t.name}"
    else
      if t.changed?
        t.save!
        log << "UPDATED_TRACKER: #{t.id}:#{t.name}"
      else
        log << "EXISTS_TRACKER: #{t.id}:#{t.name}"
      end
    end
  end

  # Statuses
  statuses = {
    'RFP' => [['Submitted', false], ['Accepted', false], ['Rejected', false]],
    'Q&A' => [['Open', false], ['Answered', false], ['Closed', true]],
    'Report' => [['Open', false], ['Acknowledged', false]]
  }
  statuses.each do |group, arr|
    arr.each_with_index do |(name, closed), idx|
      s = IssueStatus.where(name: name).first_or_initialize
      begin
        s.is_closed = closed
        s.position = s.position || (IssueStatus.maximum(:position) || 0) + 1
        s.save!
        log << "ENSURED_STATUS: #{name} id=#{s.id} closed=#{s.is_closed}"
      rescue => e
        log << "FAILED_STATUS: #{name} #{e.class}:#{e.message}"
      end
    end
  end

  # Roles
  role_defs = {
    'Client' => %w[view_issues add_issues add_messages view_news],
    'Project Lead' => %w[add_project edit_project manage_members manage_versions manage_categories add_issues edit_issues move_issues manage_subtasks add_issue_notes edit_issue_notes view_issues]
  }
  role_defs.each do |rname, perms|
    r = Role.where(name: rname).first_or_create
    log << "ENSURED_ROLE: #{r.id}:#{r.name}"
    # assign permissions by name (Role.permissions is an array of permission names)
    begin
      existing = (r.permissions || [])
      new_perms = (existing + perms).map(&:to_s).uniq
      r.permissions = new_perms
      r.save!
      log << "ROLE_PERMS: #{r.name}=#{r.permissions.join(', ')}"
    rescue => e
      log << "ERR_ASSIGN_PERM: #{rname} #{e.class}:#{e.message}"
    end
  end

  # Basic workflow transitions: allow Project Lead to transition RFP statuses
  # WorkflowTransition model exists in Redmine; create transitions for Project Lead on RFP tracker
  begin
    pl = Role.find_by(name: 'Project Lead')
    client = Role.find_by(name: 'Client')
    rfp_tracker = Tracker.find_by(name: 'RFP')
    if pl && rfp_tracker
      # allow pl to change between Submitted <-> Accepted/Rejected and to other statuses
      submitted = IssueStatus.find_by(name: 'Submitted')
      accepted = IssueStatus.find_by(name: 'Accepted')
      rejected = IssueStatus.find_by(name: 'Rejected')
      [submitted, accepted, rejected].compact.each do |from|
        [submitted, accepted, rejected].compact.each do |to|
          unless WorkflowTransition.exists?(role_id: pl.id, tracker_id: rfp_tracker.id, old_status_id: from.id, new_status_id: to.id)
            WorkflowTransition.create!(role_id: pl.id, tracker_id: rfp_tracker.id, old_status_id: from.id, new_status_id: to.id)
            log << "CREATED_WORKFLOW_TRANSITION: PL #{from.name}->#{to.name}"
          end
        end
      end
    else
      log << "SKIP_WORKFLOW_RFP: missing Project Lead or RFP tracker"
    end
  rescue => e
    log << "WORKFLOW_ERR: #{e.class}:#{e.message}"
  end

  # Q&A workflow: allow Client to close Q&A after answered, allow Project Lead to answer
  begin
    q_tracker = Tracker.find_by(name: 'Q&A')
    open_s = IssueStatus.find_by(name: 'Open')
    answered_s = IssueStatus.find_by(name: 'Answered')
    closed_s = IssueStatus.find_by(name: 'Closed')
    if q_tracker && client && pl && open_s && answered_s && closed_s
      # Project Lead: Open->Answered
      unless WorkflowTransition.exists?(role_id: pl.id, tracker_id: q_tracker.id, old_status_id: open_s.id, new_status_id: answered_s.id)
        WorkflowTransition.create!(role_id: pl.id, tracker_id: q_tracker.id, old_status_id: open_s.id, new_status_id: answered_s.id)
        log << "CREATED_WORKFLOW: PL Open->Answered (Q&A)"
      end
      # Client: Answered->Closed
      unless WorkflowTransition.exists?(role_id: client.id, tracker_id: q_tracker.id, old_status_id: answered_s.id, new_status_id: closed_s.id)
        WorkflowTransition.create!(role_id: client.id, tracker_id: q_tracker.id, old_status_id: answered_s.id, new_status_id: closed_s.id)
        log << "CREATED_WORKFLOW: Client Answered->Closed (Q&A)"
      end
    else
      log << "SKIP_QA_WORKFLOW: missing objects"
    end
  rescue => e
    log << "QAWORK_ERR: #{e.class}:#{e.message}"
  end

  log << "COMPLETED: #{Time.now}"
rescue => e
  log << "FATAL: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/setup_rfp_qa_workflow_out.txt', log.join("\n"))
puts log.join("\n")
