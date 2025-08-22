# scripts/list_rfp_projects_safe.rb
# Load the Rails environment without `rails` binary and list rfp-* projects
require File.expand_path('../config/environment', __dir__)
puts Project.where("identifier LIKE ?", "rfp-%").map{|pr| {id: pr.id, identifier: pr.identifier, name: pr.name}}.to_json
