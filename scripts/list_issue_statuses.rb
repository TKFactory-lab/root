# scripts/list_issue_statuses.rb
File.open('/tmp/issue_statuses.txt','w') do |f|
  begin
    f.puts "IssueStatus.count = #{IssueStatus.count}"
    IssueStatus.order(:position).each do |s|
      f.puts "id=#{s.id} name=#{s.name.inspect} is_closed=#{s.is_closed} position=#{s.position} default_done_ratio=#{s.default_done_ratio}"
    end
  rescue => e
    f.puts "ERROR: #{e.class}: #{e.message}"
  end
end
