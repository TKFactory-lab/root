# scripts/check_boss_file.rb
# Writes membership relationship checks into /tmp/check_results.txt (file-based to avoid stdout capture issues)
File.open('/tmp/check_results.txt','w') do |f|
  begin
    kt = User.find_by(login: 'ktakada')
    if kt
      f.puts "ktakada: id=#{kt.id} admin=#{!!kt.admin}"
    else
      f.puts "ktakada: MISSING"
    end
  rescue => e
    f.puts "ktakada lookup failed: #{e.class}: #{e.message}"
  end

  agents = %w[nobu hide yasu]
  agents.each do |a|
    begin
      u = User.find_by(login: a)
      if u
        f.puts "#{a}: id=#{u.id} admin=#{!!u.admin}"
        begin
          ms = u.memberships.includes(:project, :roles) rescue []
          if ms.any?
            ms.each do |m|
              proj = m.project rescue nil
              roles = (m.roles.map(&:name) rescue [])
              if proj
                f.puts "  member of project=#{proj.name} (id=#{proj.id}) roles=#{roles.inspect}"
              else
                f.puts "  membership with missing project id=#{m.project_id} roles=#{roles.inspect}"
              end
            end
          else
            f.puts "  no memberships"
          end
        rescue => e
          f.puts "  memberships check failed: #{e.class}: #{e.message}"
        end

        if kt
          begin
            u_pids = u.memberships.map(&:project_id) rescue []
            kt_pids = kt.memberships.map(&:project_id) rescue []
            common = u_pids & kt_pids
            if common.any?
              common.each do |pid|
                p = Project.find_by(id: pid) rescue nil
                kt_roles = kt.memberships.where(project_id: pid).map{|m| m.roles.map(&:name)}.flatten rescue []
                u_roles = u.memberships.where(project_id: pid).map{|m| m.roles.map(&:name)}.flatten rescue []
                f.puts "  common project: #{p ? p.name : pid} (id=#{pid}) kt_roles=#{kt_roles.inspect} #{a}_roles=#{u_roles.inspect}"
              end
            else
              f.puts "  no common projects with ktakada"
            end
          rescue => e
            f.puts "  common project check failed: #{e.class}: #{e.message}"
          end
        end
      else
        f.puts "#{a}: MISSING"
      end
    rescue => e
      f.puts "#{a} check failed: #{e.class}: #{e.message}"
    end
  end
end
