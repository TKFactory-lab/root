# scripts/setup_rfp_project.rb
# Create a fixed RFP intake project and ensure ktakada/nobu are members with correct roles.
log = []
begin
  proj_ident = 'crewai-rfps'
  proj_name = 'CrewAI RFP Intake'
  p = Project.find_by(identifier: proj_ident) || Project.find_by(name: proj_name)
  if p.nil?
    p = Project.new(name: proj_name, identifier: proj_ident, description: 'Incoming RFPs - ktakada issues RFP here')
    p.is_public = false
    p.save!
    log << "CREATED_PROJECT: #{p.id}:#{p.name}"
  else
    log << "PROJECT_EXISTS: #{p.id}:#{p.name}"
  end

  # Ensure trackers: RFP must be available
  rfp_tracker = Tracker.find_by(name: 'RFP')
  if rfp_tracker
    unless p.trackers.map(&:id).include?(rfp_tracker.id)
      p.trackers = (p.trackers | [rfp_tracker])
      p.save!
      log << "ADDED_TRACKER_RFP: #{rfp_tracker.name} to #{p.identifier}"
    else
      log << "TRACKER_ALREADY_PRESENT: RFP"
    end
  else
    log << "MISSING_TRACKER_RFP"
  end

  # Ensure roles and members
  kt = User.find_by(login: 'ktakada')
  nb = User.find_by(login: 'nobu')
  client_role = Role.find_by(name: 'Client')
  pl_role = Role.find_by(name: 'Project Lead')
  if kt && client_role
    unless p.members.any?{|m| m.user_id == kt.id }
      Member.create!(project_id: p.id, user_id: kt.id, role_ids: [client_role.id])
      log << "ADDED_MEMBER: ktakada as Client"
    else
      log << "MEMBER_EXISTS: ktakada"
    end
  else
    log << "MISSING_KT_OR_CLIENT_ROLE"
  end
  if nb && pl_role
    unless p.members.any?{|m| m.user_id == nb.id }
      Member.create!(project_id: p.id, user_id: nb.id, role_ids: [pl_role.id])
      log << "ADDED_MEMBER: nobu as Project Lead"
    else
      log << "MEMBER_EXISTS: nobu"
    end
  else
    log << "MISSING_NB_OR_PL_ROLE"
  end

rescue => e
  log << "ERROR: #{e.class}: #{e.message}"
  log.concat e.backtrace
end
File.write('/tmp/setup_rfp_project_out.txt', log.join("\n"))
puts log.join("\n")
