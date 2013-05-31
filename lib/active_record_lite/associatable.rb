require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    define_method(name) do
      if params[:class_name]
        other_class = params[:class_name].constantize
      else
        other_class = name.to_s.camelize.constantize
      end
      
      other_table_name = other_class.table_name
      
      primary_key = params[:primary_key] || :id
      foreign_key = params[:foreign_key] || ("#{name}" + "_id").to_sym
      
      query = <<-SQL
      SELECT *
      FROM #{other_table_name}
      WHERE #{primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.send(foreign_key))

      other_class.parse_all(result).first
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      if params[:class_name]
        other_class = params[:class_name].camelize.constantize
      else
        other_class = name.to_s.singularize.camelize.constantize
      end

      other_table_name = other_class.table_name
      primary_key = params[:primary_key] || :id
      foreign_key = params[:foreign_key] || ("#{(self.class).camelize}" + "_id").to_sym

      query = <<-SQL
      SELECT *
      FROM #{other_table_name}
      WHERE #{foreign_key} = ?
      SQL

      results = DBConnection.execute(query, self.send(primary_key))

      other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
