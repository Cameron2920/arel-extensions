require 'arel_extensions/nodes'
require 'arel_extensions/nodes/function'
require 'arel_extensions/nodes/concat'
require 'arel_extensions/nodes/cast'

require 'arel_extensions/nodes/date_diff'
require 'arel_extensions/nodes/duration'
require 'arel_extensions/nodes/wday'
require 'arel_extensions/nodes/union'
require 'arel_extensions/nodes/union_all'

module ArelExtensions
  module Math
    #function + between
    #String and others (convert in string)  allows you to concatenate 2 or more strings together.
    #Date and integer adds or subtracts a specified time interval from a date.
    def +(other)
	  return ArelExtensions::Nodes::Concat.new [self, other] if self.is_a?(Arel::Nodes::Quoted)	  
	  if self.is_a?(Arel::Nodes::Grouping)
		if self.expr.left.is_a?(String) || self.expr.right.is_a?(String) 
		  return ArelExtensions::Nodes::Concat.new [self, other]
		else		
		  return Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
		end
	  end	  
	  if self.is_a?(ArelExtensions::Nodes::Function)		  
		  return case self.return_type
		  when :string, :text			
			ArelExtensions::Nodes::Concat.new [self, other]
		  when :integer, :decimal, :float, :number, :int
			Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
		  when :date, :datetime
			ArelExtensions::Nodes::DateAdd.new [self, other]
		  else
			ArelExtensions::Nodes::Concat.new [self, other]
		  end 
	  end
	  if self.is_a?(Arel::Nodes::Function)
		return Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
	  end
	  col = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s]
	  if (!col) #if the column doesn't exist in the database
		Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new(self, other))
	  else
		arg = col.type
		if arg == :integer || (!arg)
		  other = other.to_i if other.is_a?(String)
		  Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
		elsif arg == :decimal || arg == :float
		  other = Arel.sql(other) if other.is_a?(String) # Arel should accept Float & BigDecimal!
		  Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
		elsif arg == :datetime || arg == :date
		  ArelExtensions::Nodes::DateAdd.new [self, other]
		elsif arg == :string || arg == :text
		  ArelExtensions::Nodes::Concat.new [self, other]
		end        
	  end
    end

    #function returns the time between two dates
    #function returns the substraction between two ints
    def -(other)
	  return case self.return_type
	  when :string, :text # ???
		Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other)) # ??
	  when :integer, :decimal, :float, :number
		Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
	  when :date, :datetime
		ArelExtensions::Nodes::DateSub.new [self, other]
	  else
		Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
	  end if self.is_a?(ArelExtensions::Nodes::Function)
	  col = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s]
	  if (!col) #if the column doesn't exist in the database
		return Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
	  else
		arg = col.type
		if (arg == :date || arg == :datetime)
			case other
			when Arel::Attributes::Attribute
			  col2 = Arel::Table.engine.connection.schema_cache.columns_hash(other.relation.table_name)[other.name.to_s]
			  if (!col2) #if the column doesn't exist in the database				
				ArelExtensions::Nodes::DateSub.new [self, other]
			  else
				arg2 = col2.type
				if arg2 == :date || arg2 == :datetime
				  ArelExtensions::Nodes::DateDiff.new [self, other]
				else
				  ArelExtensions::Nodes::DateSub.new [self, other]
				end
			  end  
			when Arel::Nodes::Node, DateTime, Time, String, Date
			  ArelExtensions::Nodes::DateDiff.new [self, other]
			when Integer
			  ArelExtensions::Nodes::DateSub.new [self, other]
			end
		else
			case other
			when Integer, Float, BigDecimal
			  Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, Arel.sql(other.to_s)))
			when String
			  Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, Arel.sql(other)))
			else
			  Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
			end
		end
	  end
    end
     
  end
end
