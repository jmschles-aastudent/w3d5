require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name.underscore
  end

  def self.table_name
    @table_name
  end

  def self.all
    rows = DBConnection.execute("SELECT * FROM #{@table_name}")
    rows.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    rows = DBConnection.execute("SELECT * FROM #{@table_name} WHERE id = #{id}")
    rows.map do |row|
      self.new(row)
    end
  end

  def create
    attrs_string = self.class.attributes.join(", ")
    qmarks_string = (['?'] * self.class.attributes.count).join(", ")

    query = <<-SQL
    INSERT INTO #{self.class.table_name}
    (#{attrs_string})
    VALUES (#{qmarks_string})
    SQL

    p query
    
    DBConnection.execute(query, *attribute_values)
    @id = DBConnection.last_insert_row_id

    p @id
  end

  def update
    set_line = self.class.attributes.map do |attr|
      "#{attr} = ?"
    end.join(", ")

    query = <<-SQL
    UPDATE #{self.class.table_name}
    SET #{set_line}
    WHERE id = #{@id}
    SQL

    DBConnection.execute(query, *attribute_values)
  end

  def save
    (@id.nil?) ? create : update 
  end

  def attribute_values
    self.class.attributes.map do |attr|
      self.send("#{attr}")
    end
  end
end
