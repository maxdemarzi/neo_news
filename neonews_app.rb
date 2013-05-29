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
              RETURN ID(me), me.text, me.description, me.type, ID(related), related.text, related.description, related.type"

    connections = neo.execute_query(cypher)["data"]   
    connections.collect{|n| {"source" => n[0], "source_data" => {:label => n[1], 
                                                                 :description => n[2],
                                                                 :type => n[3] },
                             "target" => n[4], "target_data" => {:label => n[5], 
                                                                 :description => n[6],
                                                                 :type => n[7]}} }.to_json
  end
end