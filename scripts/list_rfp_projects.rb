# scripts/list_rfp_projects.rb
p Project.where("identifier LIKE ?", "rfp-%").map{|pr| {id: pr.id, identifier: pr.identifier, name: pr.name}}
