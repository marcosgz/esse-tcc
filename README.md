# Exmplo de uso gem esse

Essa pequena aplicação foi desenvolvida no trabalho de conclusão de curso de engenharia de software.

Como intuito de testar a [esse](https://github.com/marcosgz/esse) desenvolvido no TCC, foi criado uma aplicação seguindo os requisitos de extração de dados de múltiplas fontes, normalização, classificação e carregamento dos dados para um índice ElasticSearch. A aplicação consiste em um índice composto por dados eleitorais de candidatos e partidos e suas respectivos endereço eletrônicos.

Os dados foram coletados do Portal de Dados Abertos do TSE. O portal dispo-nibiliza dados gerados ou custodiados pelo TSE, que podem ser livremente acessados,utilizados, modificados e compartilhados por qualquer pessoa. A Figura abaixo representa a estrutura de dados do índice que é composto pelos tipos "candidato"e "par-tido"ha ser obtido como resultado final da aplicação.

## Desenvolvimento

Estrutura inicial do projeto:

```
marcos@Marcos-MacBook-Pro-M1 ~/esse-tcc $ tree .                [ruby-2.6.9p207]
.
├── Gemfile
├── Gemfile.lock
└── data
    ├── consulta_cand_2020_BRASIL.csv
    └── partidos_politicos_registrados_contato.csv
```
_Note que os arquivos data/*.csv deverão estar compactados no repositório para otimizar espaço_

Adicionar dependência [esse](https://github.com/marcosgz/esse)  no projeto:

```
$ bundle add esse       [ruby-2.6.9p207]
Fetching gem metadata from https://rubygems.org/...........
Resolving dependencies...
Fetching gem metadata from https://rubygems.org/.......
Resolving dependencies...
Using bundler 2.3.5
...
Installing esse 0.1.1
```

Gerar o arquivo de configuração [config/esse](config/esse.rb) opcional com definições globais do [esse](https://github.com/marcosgz/esse).

```
$ bundle exec esse install
      create  config/esse.rb
```

Gerar um índice denominado ContatosEleitoraisIndex com os tipos: candidato e partido:

```
$ bundle exec esse generate index ContatosEleitoraisIndex candidato partido
Loading configuration file: config/esse.rb
      create  app/indices/contatos_eleitorais_index.rb
      create  app/indices/contatos_eleitorais_index/templates/candidato_mapping.json
      create  app/indices/contatos_eleitorais_index/serializers/candidato_serializer.rb
      create  app/indices/contatos_eleitorais_index/collections/candidato_collection.rb
      create  app/indices/contatos_eleitorais_index/templates/partido_mapping.json
      create  app/indices/contatos_eleitorais_index/serializers/partido_serializer.rb
      create  app/indices/contatos_eleitorais_index/collections/partido_collection.rb
```

Iniciar o serviço elasticsearch 5.6 (Ou use o script [./bin/start_es](./bin/start_es) do repositório):

```
docker run --rm --env node.name=es1 \
  --env discovery.zen.minimum_master_nodes=1 \
  --env http.port=9200 \
  --env 'ES_JAVA_OPTS=-Xms1g -Xmx1g -da:org.elasticsearch.xpack.ccr.index.engine.FollowingEngineAssertions' \
  --env cluster.name=docker-elasticsearch \
  --env cluster.routing.allocation.disk.threshold_enabled=false \
  --env bootstrap.memory_lock=true \
  --env xpack.security.enabled=false \
  --env discovery.zen.ping.unicast.hosts=es1:9300, \
  --ulimit nofile=65536:65536 \
  --ulimit memlock=-1:-1 \
  --publish 9200:9200 \
  --publish 9300:9300 \
  --detach \
  --network=esse \
  --name=es1 \
  docker.elastic.co/elasticsearch/elasticsearch:5.6.16
```

Verificando se serviço elasticsearch está funcionando:

```
$ curl localhost:9200
{
  "name" : "es1",
  "cluster_name" : "docker-elasticsearch",
  "cluster_uuid" : "C5DRBDM5TGiGQHRsrwj5TA",
  "version" : {
    "number" : "5.6.16",
    "build_hash" : "3a740d1",
    "build_date" : "2019-03-13T15:33:36.565Z",
    "build_snapshot" : false,
    "lucene_version" : "6.6.1"
  },
  "tagline" : "You Know, for Search"
}
```

### Definição do mapping

As definições de mapping para o tipo **partido** ([candidatos_eleitorais_index/templates/partido_mapping.json](./app/indices/contatos_eleitorais_index/templates/partido_mapping.json)):
```json
{
  "nome": {
    "type": "string",
    "index": "analyzed"
  },
  "sigla": {
    "type": "keyword"
  },
  "num_legenda": {
    "type": "short"
  },
  "email": {
    "type": "keyword"
  }
}
```

As definições de mapping para o tipo **candidato** ([candidatos_eleitorais_index/templates/candidato_mapping.json](./app/indices/contatos_eleitorais_index/templates/candidato_mapping.json)):

```json
{
  "nome": {
    "type": "string",
    "index": "analyzed"
  },
  "cargo": {
    "type": "keyword"
  },
  "num_legenda": {
    "type": "short"
  },
  "email": {
    "type": "keyword"
  }
}
```

### Collection

Collection é usado para extração dos dados. Nesse caso vamos usar arquivos CSV como fonte dos dados para simplifiar a solução.
Para isso foi criado um service usado para ler os arquivos CSV, e selecionar apenas os dados validos. ([services/csv_reader.rb](./app/services/csv_reader.rb)):

```ruby
class CSVReader
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def initialize(source, headers: true, col_sep: ';', **opts)
    raise(ArgumentError, "File #{source} not found") unless File.exist?(source)

    @table = CSV.parse(File.read(source), headers: headers, col_sep: col_sep, **opts)
  end

  # @return [Array<CSV::Row>]
  # @param options [Hash] List of filters
  # @option email [String] The column where the email is stored to validate email format
  # @option required [Array<String>] The columns that must be present in the row
  def table(email: nil, required: [])
    @table.select { |row| valid_row?(row, required: required, email: email) }
  end

  private

  def valid_row?(row, required: , email: )
    (row.headers & required).size == required.size && \
      VALID_EMAIL_REGEX.match?(row[email])
  end
end
```

E os collections ajustados para carregar os dados usando o `CSVReader`:

* [CandidatoCollection](./app/indices/contatos_eleitorais_index/collections/candidato_collection.rb):

```ruby
# frozen_string_literal: true

class ContatosEleitoraisIndex < Esse::Index
  module Collections
    class CandidatoCollection
      include Enumerable

      SOURCE = File.expand_path('../../../../../data/consulta_cand_2020_BRASIL.csv', __FILE__).freeze
      VALIDATE = {
        required: %w[SQ_CANDIDATO NM_CANDIDATO NM_EMAIL],
        email: 'NM_EMAIL'
      }

      # @param params [Hash] List of parameters
      # @option params [String] :source Path to the CSV file
      # @option params [Integer] :batch_size Number of rows to process in each batch
      def initialize(source: SOURCE, batch_size: 1000, **params)
        @reader = CSVReader.new(source)
        @batch_size = batch_size
        @params = params
      end

      # Find all partido in batches
      #
      # @yield [Array<CSV::Row>, Hash]
      def each
        @reader.table(**VALIDATE).each_slice(@batch_size) do |batch|
          yield(batch, **@params)
        end
      end
    end
  end
end
```

* [PartidoCollection](./app/indices/contatos_eleitorais_index/collections/partido_collection.rb):
```ruby
# frozen_string_literal: true

class ContatosEleitoraisIndex < Esse::Index
  module Collections
    class PartidoCollection
      include Enumerable

      SOURCE = File.expand_path('../../../../../data/partidos_politicos_registrados_contato.csv', __FILE__).freeze
      VALIDATE = {
        required: %w[NR_PARTIDO NOME EMAIL],
        email: 'EMAIL'
      }

      # @param params [Hash] List of parameters
      # @option params [String] :source Path to the CSV file
      # @option params [Integer] :batch_size Number of rows to process in each batch
      def initialize(source: SOURCE, batch_size: 1000, **params)
        @reader = CSVReader.new(source)
        @batch_size = batch_size
        @params = params
      end

      # Find all partido in batches
      #
      # @yield [Array<CSV::Row>, Hash]
      def each
        @reader.table(**VALIDATE).each_slice(@batch_size) do |batch|
          yield(batch, **@params)
        end
      end
    end
  end
end
```

### Serializers

Os serializers são usados para transformar os dados em um formato que o Elasticsearch aceita. Os serializers são inicializados com a linha da do CSV vindos do collection. Segue abaixo os serializers do índice candidatos_eleitorais_index:

* [CandidatoSerializer](./app/indices/contatos_eleitorais_index/serializers/candidato_serializer.rb):
```ruby
class ContatosEleitoraisIndex < Esse::Index
  module Serializers
    class CandidatoSerializer
      def initialize(row, **_params)
        @row = row
      end

      def to_h
        {
          _id: @row['SQ_CANDIDATO'].to_i,
          name: @row['NM_CANDIDATO'],
          cargo: @row['DS_CARGO'],
          email: @row['NM_EMAIL'],
          num_legenda: @row['NR_PARTIDO'],
        }
      end
    end
  end
end

```

* [PartidoSerializer](./app/indices/contatos_eleitorais_index/serializers/partido_serializer.rb):
```ruby
class ContatosEleitoraisIndex < Esse::Index
  module Serializers
    class PartidoSerializer
      def initialize(row, **_params)
        @row = row
      end

      def to_h
        {
          _id: @row['NR_PARTIDO'].to_i,
          name: @row['NOME'],
          sigla: @row['SIGLA'],
          email: @row['EMAIL'],
          num_legenda: @row['NR_PARTIDO'].to_i,
        }
      end
    end
  end
end

### Index final

O framework esse permite a definição de indices e colections diretamente na classe principal do índice ou em classes separadas. No exemplo abaixo collection e mapping foram definidos separadamentes.

* [CandidatosEleitoraisIndex](./app/indices/contatos_eleitorais_index.rb):

```ruby
class ContatosEleitoraisIndex < Esse::Index
  define_type :candidato do
    collection Collections::CandidatoCollection
    serializer Serializers::CandidatoSerializer
  end

  define_type :partido do
    collection Collections::PartidoCollection
    serializer Serializers::PartidoSerializer
  end
end
```
