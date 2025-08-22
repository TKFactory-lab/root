#!/usr/bin/env ruby
# scripts/inspect_rfp_projects.rb
require File.expand_path('../config/environment', __dir__)
require 'json'

out = []
Project.where("identifier LIKE ?", "rfp-%").each do |p|
  members = p.members.map do |m|
    { user: (m.user ? m.user.login : nil), roles: m.roles.map(&:name) }
  end
  out << {
    id: p.id,
    identifier: p.identifier,
    name: p.name,
    members: members,
    trackers: p.trackers.map(&:name),
    categories: p.issue_categories.map(&:name),
    versions: p.versions.map(&:name)
  }
end

puts JSON.pretty_generate(out)
