# frozen_string_literal: true

require_relative '../services/csv_reader'
class ContatosEleitoraisIndex < Esse::Index
  define_type :candidato do
    mapping {
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

    collection do |**context, block|
      source = context[:source] || File.expand_path('../../../data/contatos_eleitorais.csv', __FILE__)
      CSVReader.new(source).each_slice(1000) do |batch|
        block.call batch, **context
      end
    end

    serializer do |row, **context|
      {
        _id: row['SQ_CANDIDATO'].to_i,
        name: row['NM_CANDIDATO'],
        cargo: row['DS_CARGO'],
        email: row['NM_EMAIL'],
        num_legenda: row['NR_PARTIDO'],
      }
    end
  end

  define_type :partido do
    mapping {
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

    collection do |**context, block|
      source = context[:source] || File.expand_path('../../../data/partidos_politicos_registrados_contato.csv', __FILE__)
      CSVReader.new(source).each_slice(1000) do |batch|
        block.call batch, **context
      end
    end

    serializer do |row, **context|
      {
        _id: row['NR_PARTIDO'].to_i,
        name: row['NOME'],
        sigla: row['SIGLA'],
        email: row['EMAIL'],
        num_legenda: row['NR_PARTIDO'].to_i,
      }
    end
  end
end
