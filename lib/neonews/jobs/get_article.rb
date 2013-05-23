module Job
  class GetArticle
    include Sidekiq::Worker
    sidekiq_options :retry => 3, unique: true

    def perform(url)
      meta_article = HTTPClient.get_content(url)
      meta_article_html = Nokogiri::HTML(meta_article)
      article_url = URI.unescape(meta_article_html.xpath("//iframe").first["src"].split("&url=").last.gsub("&xcust=feedzilla",""))

      @entities = Oj.load(HTTPClient.post_content("http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities",
      {:url => article_url, 
       :apikey => "0b1ac211c8d4469dd04013aa02ad0df23fb102e2",
       :outputMode => "json"}),
       {:'Accept-encoding' => "gzip"})["entities"]
      
      unless @entities.empty?
       
        NEO4J_POOL.with do |neo|
          @article_node = neo.create_unique_node("articles", "uri", article_url, {"uri" => article_url})
        end
      
        # Add entities to the Graph
        commands = []
        @entities.each do |entity|
          text = entity["text"]
          if entity["disambiguated"]
            text = entity["disambiguated"]["name"] 
          end
          commands << [:create_unique_node, "entities", "text", text, {"text" => text, 
                                                                       "type" => entity["type"] }]
        end
      
        NEO4J_POOL.with do |neo|
          @batch_result = neo.batch *commands
        end

        # Add entity types to an index
        commands = []
        @batch_result.each do |b|
          commands << [:add_node_to_index, "entities", "type",  b["body"]["data"]["type"], b["body"]["self"].split("/").last]
        end
      
        NEO4J_POOL.with do |neo|
          @batch_result = neo.batch *commands
        end
      
        # Connect entities to Article
        commands = []
        @batch_result.each do |b|
          commands << [:create_relationship, "MENTIONED", @article_node, b["body"]["self"].split("/").last]
        end
      
        NEO4J_POOL.with do |neo|
          @batch_result = neo.batch *commands
        end
      end
    end
  end
end
