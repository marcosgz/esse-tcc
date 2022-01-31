# frozen_string_literal: true

Esse.configure do |config|
  config.indices_directory = File.expand_path('../../app/indices', __FILE__)
  config.cluster(:default) do |cluster|
    cluster.index_prefix = "esse_tcc"
    cluster.client = Elasticsearch::Client.new(url: ENV.fetch('ESSE_CLUSTER_DEFAULT_URL', 'http://localhost:9200'))
    cluster.index_settings = {
      number_of_shards: 1,
      number_of_replicas: 0,
    }
  end
end
