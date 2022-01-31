# frozen_string_literal: true

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
