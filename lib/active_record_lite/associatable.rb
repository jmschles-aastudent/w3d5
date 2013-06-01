require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  # It would be great to use all this...

  # def other_class
  #   if params[:class_name]
  #     params[:class_name].constantize
  #   else
  #     name.to_s.camelize.constantize
  #   end
  # end

  # def other_table
  #   other_class.table_name
  # end
end

class BelongsToAssocParams < AssocParams
  attr_reader :other_table_name, :foreign_key, :primary_key, :other_class
  def initialize(name, params)
    # @other_class = super(other_class)
    # @other_table_name = super(other_table)
    if params[:class_name]
      @other_class = params[:class_name]
    else
      @other_class = name.to_s.camelize
    end
    # @other_table_name = @other_class.constantize.table_name
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || ("#{name}" + "_id").to_sym
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_reader :other_table_name, :foreign_key, :primary_key, :other_class
  def initialize(name, params, self_class)
    # @other_class = super(other_class)
    # @other_table_name = super(other_table)
    if params[:class_name]
      @other_class = params[:class_name]
    else
      @other_class = name.to_s.singularize.camelize
    end
    # @other_table_name = @other_class.constantize.table_name
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || ("#{self_class.camelize}" + "_id").to_sym
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})

    assoc_params[name] = BelongsToAssocParams.new(name, params)

    define_method(name) do

      aps = BelongsToAssocParams.new(name, params)
      
      query = <<-SQL
      SELECT *
      FROM #{aps.other_class.constantize.table_name}
      WHERE #{aps.primary_key} = ?
      SQL

      result = DBConnection.execute(query, self.send(aps.foreign_key))

      aps.other_class.constantize.parse_all(result).first
    end
  end

  def has_many(name, params = {})
    define_method(name) do

      aps = HasManyAssocParams.new(name, params, self.class)

      query = <<-SQL
      SELECT *
      FROM #{aps.other_class.constantize.table_name}
      WHERE #{aps.foreign_key} = ?
      SQL

      results = DBConnection.execute(query, self.send(aps.primary_key))

      aps.other_class.constantize.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)

    define_method(name) do

      human = self.class.assoc_params[assoc1]
      house = human.other_class.constantize.assoc_params[assoc2]

      p human
      p house

      human_table = human.other_class.constantize.table_name
      house_table = house.other_class.constantize.table_name

      # p "#{human_table}.#{assoc2_params.primary_key}"

      p "#{house.foreign_key}"
      p "#{human_table.foreign_key}"

      query = <<-SQL
      SELECT #{house_table}.*
      FROM #{house_table}
      JOIN #{human_table}
      ON #{human_table}.#{human.primary_key}
      = #{house.foreign_key}
      WHERE #{house_table}.#{house.primary_key} = #{house.foreign_key}
      SQL

      DBConnection.execute(query)
    end

  end
end
