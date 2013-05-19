require 'sinatra/base'

class App < Sinatra::Base
  
  configure :development do |config|
    register Sinatra::Reloader
  end
  
  set :haml, :format => :html5 
  set :app_file, __FILE__

  get '/' do
    @neoid = params["neoid"]
    haml :index
  end
  
  get '/search' do 
    content_type :json
    neo = Neography::Rest.new    

    cypher = "START me=node:entities({query}) 
              RETURN ID(me), me.label
              ORDER BY me.label
              LIMIT 15"

    neo.execute_query(cypher, {:query => "label:*#{params[:term]}* OR uri:*#{params[:term]}*" })["data"].map{|x| { label: x[1], value: x[0]}}.to_json   
  end

  get '/edges/:id' do
    content_type :json
    neo = Neography::Rest.new    

    cypher = "START me=node(#{params[:id]}) 
              MATCH me -- related
              RETURN me.uri, COALESCE(me.label?, me.uri), related.uri, COALESCE(related.label?, related.uri)"

    connections = neo.execute_query(cypher)["data"]   
    connections.collect{|n| {"source" => n[0], "source_data" => n[1], "target" => n[2], "target_data" => n[3]} }.to_json
  end

  get '/external/:id' do
    content_type :json
    doc = Pismo::Document.new(URI.unescape(params[:id]))
    {:title => doc.title, :author => doc.author, :lede => doc.lede, :keywords => doc.keywords}.to_json
  end
  
end