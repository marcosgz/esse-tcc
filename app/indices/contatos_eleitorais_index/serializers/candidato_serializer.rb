# frozen_string_literal: true

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
