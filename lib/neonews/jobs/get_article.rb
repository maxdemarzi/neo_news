module Job
  class GetArticle
    include Sidekiq::Worker
    sidekiq_options :retry => 3, unique: true

    def perform(url)
      meta_article = HTTPClient.get_content(url)
      meta_article_html = Nokogiri::HTML(meta_article)
      article_url = URI.unescape(meta_article_html.xpath("//iframe").first["src"].split("&url=").last).gsub("&xcust=feedzilla","")

      NERD_POOL.with do |nerd|
        @entities = nerd.extract(article_url)
      end

      NEO4J_POOL.with do |neo|
        @article_node = neo.create_unique_node("articles", "uri", article_url, {"uri" => article_url})
      end
      
      # Add entities to the Graph
      commands = []
      @entities.delete_if {|entity| entity["uri"].nil? }
      @entities.each do |entity|
        commands << [:create_unique_node, "entities", "uri", entity["uri"], {"uri" => entity["uri"], 
                                                                             "label" => entity["label"],
                                                                             "type" => entity["nerdType"] }]
      end
      NEO4J_POOL.with do |neo|
        @batch_result = neo.batch *commands
      end

      # Add entity labels to an index
      commands = []
      @batch_result.each do |b|
        commands << [:add_node_to_index, "entities", "label",  b["body"]["data"]["label"], b["body"]["self"].split("/").last]
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
