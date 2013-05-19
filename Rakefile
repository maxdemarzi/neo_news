require 'neography/tasks'
require './lib/neonews.rb'

namespace :neo4j do
  task :create do
    neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    neo.create_node_index("entities", "fulltext")
  end
end

namespace :neonews do
  task :collect do
    Job::GetNews.perform_async
  end
end