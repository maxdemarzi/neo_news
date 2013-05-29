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
              RETURN ID(me), me.text
              ORDER BY me.text
              LIMIT 15"

    neo.execute_query(cypher, {:query => "text:*#{params[:term]}* OR uri:*#{params[:term]}*" })["data"].map{|x| { label: x[1], value: x[0]}}.to_json   
  end

  get '/edges/:id' do
    content_type :json
    neo = Neography::Rest.new    

    cypher = "START me=node(#{params[:id]}) 
              MATCH me -- related
              RETURN ID(me), me.text, me.description, ID(related), related.text, related.description"

    connections = neo.execute_query(cypher)["data"]   
    connections.collect{|n| {"source" => n[0], "source_data" => {:label => n[1], :description => n[2]}, "target" => n[3], "target_data" => {:label => n[4], :description => n[5]}} }.to_json
  end

  get '/external/:id' do
    content_type :json
    redis = Redis.new
        
    content = redis.cache(:key => params[:id]) do
      doc = Pismo::Document.new(URI.unescape(params[:id]))
      {:title => doc.title, :author => doc.author, :lede => doc.lede, :keywords => doc.keywords}.to_json
    end
    content
  end
  
end