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
