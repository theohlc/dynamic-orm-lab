require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

    def self.table_name
        self.name.downcase.pluralize
    end

    def self.column_names
        data = DB[:conn].execute("pragma table_info('#{table_name}')")

        columns = []
        
        data.each do |row|
            columns << row['name']            
        end
        columns.compact
    end

    def initialize(data = {})
        data.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.name.downcase.pluralize
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |name|
            values << "'#{send(name)}'" unless send(name).nil?
        end

        values.join(", ")
    end

    def save
        #binding.pry
        sql = <<-SQL
            INSERT INTO #{self.class.table_name}(#{col_names_for_insert})
            VALUES (#{values_for_insert})
            SQL

        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
        
    end

    def self.find_by_name(name)
        row = DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
    end

    def self.find_by(attribute)
        row = []
        attribute.each do |key, value|
            row = DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{key} = ?", value)
        end
        row
    end
end