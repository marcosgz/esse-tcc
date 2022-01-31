require 'csv'
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
