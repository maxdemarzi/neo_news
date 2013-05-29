neo_news
========

A POC Neo4j Application about the News

Description
--------------

We are getting the news from [FeedZilla](http://feedzilla.com), see their [REST API](https://code.google.com/p/feedzilla-api/wiki/RestApi) for details.

We are using [AlchemyAPI](http://www.alchemyapi.com) for named entity extraction, see their [Entity Extraction API](http://www.alchemyapi.com/api/entity/) for details.

Installation
----------------

    git clone git://github.com/maxdemarzi/neo_news.git
    bundle install (run gem install bundler if you don't have bundler installed)
    sudo apt-get install redis-server or brew install redis or install redis manually
    rake neo4j:install
    rake neo4j:start
    rake neo4j:create
    export REDISTOGO_URL="redis://127.0.0.1:6379/"
    export ALCHEMY_API="your alchemy api key"
    foreman start
    rake neonews:collect

On Heroku
---------

    git clone git://github.com/maxdemarzi/neo_news.git
    heroku apps:create neonews
    heroku addons:add neo4j
    heroku addons:add redistogo

    git push heroku master
    heroku ps:scale worker=1
    heroku run rake neo4j:create
    heroku run rake neonews:collect

See it running live at http://neonews.heroku.com