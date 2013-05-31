require_relative './db_connection'

module Searchable
  def where(params)
  	attr_line = params.keys.map { |key| "#{key} = ?"}.join(" AND ")

  	rows = DBConnection.execute("SELECT * 
  												FROM #{table_name}
  												WHERE #{attr_line}",
  												*params.values)

  	rows.map do |row|
  		self.new(row)
  	end
  end
end