# scripts/check_boss.rb
# Checks whether ktakada exists and whether nobu/hide/yasu share projects with ktakada
begin
  kt = User.find_by(login: 'ktakada')
  if kt
    puts "ktakada: id=#{kt.id} admin=#{!!kt.admin}"
  else
    puts "ktakada: MISSING"
  end
rescue => e
  puts "ktakada lookup failed: #{e.message}"
end

agents = %w[nobu hide yasu]
agents.each do |a|
  begin
    u = User.find_by(login: a)
    if u
      puts "#{a}: id=#{u.id} admin=#{!!u.admin}"
      ms = u.memberships.includes(:project, :roles) rescue []
      if ms.any?
        ms.each do |m|
          proj = m.project rescue nil
          roles = (m.roles.map(&:name) rescue [])
          if proj
            puts "  member of project=#{proj.name} (id=#{proj.id}) roles=#{roles.inspect}"
          else
            puts "  membership with missing project id=#{m.project_id} roles=#{roles.inspect}"
          end
        end
      else
        puts "  no memberships"
      end

      if kt
        begin
          u_pids = u.memberships.map(&:project_id) rescue []
          kt_pids = kt.memberships.map(&:project_id) rescue []
          common = u_pids & kt_pids
          if common.any?
            common.each do |pid|
              p = Project.find_by(id: pid)
              kt_roles = kt.memberships.where(project_id: pid).map{|m| m.roles.map(&:name)}.flatten rescue []
              u_roles = u.memberships.where(project_id: pid).map{|m| m.roles.map(&:name)}.flatten rescue []
              puts "  common project: #{p ? p.name : pid} (id=#{pid}) kt_roles=#{kt_roles.inspect} #{a}_roles=#{u_roles.inspect}"
            end
          else
            puts "  no common projects with ktakada"
          end
        rescue => e
          puts "  common project check failed: #{e.message}"
        end
      end
    else
      puts "#{a}: MISSING"
    end
  rescue => e
    puts "#{a} check failed: #{e.message}"
  end
end
