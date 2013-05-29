module Job
  class GetDescription
    include Sidekiq::Worker
    sidekiq_options :retry => 3, unique: true

    def perform(id, url)

      NEO4J_POOL.with do |neo|
        @node = neo.get_node(id)
      end

      begin
        description_html = HTTPClient.get_content(url)
        description_doc = Nokogiri::HTML(description_html)
        description = description_doc.xpath("//div[@id='content']//p").first.text
       
        NEO4J_POOL.with do |neo|
          neo.set_node_properties(@node, {:description => description})
        end
      rescue Exception => e
        Job::GetDescription.perform_in(15.minutes, id, url)
      end

    end
  end
end
