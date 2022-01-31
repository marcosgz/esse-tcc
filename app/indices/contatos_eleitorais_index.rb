# frozen_string_literal: true

require_relative '../services/csv_reader'
require_relative 'contatos_eleitorais_index/collections/candidato_collection'
require_relative 'contatos_eleitorais_index/collections/partido_collection'
require_relative 'contatos_eleitorais_index/serializers/candidato_serializer'
require_relative 'contatos_eleitorais_index/serializers/partido_serializer'

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
