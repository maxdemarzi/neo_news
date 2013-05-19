module Job
  class GetNews
    include Sidekiq::Worker
    sidekiq_options :retry => false

    def perform
      Job::GetNews.perform_in(6.hours)

      feed = HTTPClient.get("http://api.feedzilla.com/v1/categories/19/articles.json?order=date&count=100&title_only=1")
      parsed_feed = Oj.load(feed.body)
      parsed_feed["articles"].each do |article|
        Job::GetArticle.perform_async(article["url"])
      end
    end

  end
end
