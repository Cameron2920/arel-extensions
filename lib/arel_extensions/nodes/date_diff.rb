require 'date'

module ArelExtensions
  module Nodes
    class DateDiff < Function #difference entre colonne date et date string/date
      attr_accessor :left_node_type
      attr_accessor :right_node_type
      attr_accessor :precision

      RETURN_TYPE = :integer # by default...

      def initialize(expr, precision = 'second')
        self.precision = precision
        super expr
      end
    end

    class DateTruncate < Function
      attr_accessor :left_node_type
      attr_accessor :right_node_type
      attr_accessor :precision

      RETURN_TYPE = :datetime

      def initialize(expr)
        super expr
      end
    end

    class CurrentDate < Function
      RETURN_TYPE = :datetime

      def initialize(expr)
        super expr
      end
    end

    class StringToDate < Function
      RETURN_TYPE = :datetime

      def initialize(expr)
        super expr
      end
    end

    class DateAdd < Function
      RETURN_TYPE = :date
      attr_accessor :date_type

      def initialize expr, date_type
        col = expr.first

        if date_type
          @date_type = date_type.try(:to_sym)
        else
          case col
          when Arel::Nodes::Quoted, Arel::Nodes::SqlLiteral
            @date_type = :datetime
          else
            @date_type = type_of_attribute(col)
          end
        end

        tab = expr.map do |arg|
          convert(arg)
        end
        return super(tab)
      end

      def sqlite_value
        v = self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            return Arel::Nodes.build_quoted((v.value >= 0 ? '+' : '-') + v.inspect)
          elsif @date_type == :datetime
            return Arel::Nodes.build_quoted((v.value >= 0 ? '+' : '-') + v.inspect)
          end
        else
          return v
        end
      end

      def mysql_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date || @date_type == :datetime
            Arel.sql('INTERVAL %s' % v.inspect.sub(/s\Z/, ''))
          end
        else
          v
        end
      end

      def postgresql_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            Arel.sql("INTERVAL '%s'" % v.inspect.sub(/s\Z/, '').upcase)
          elsif @date_type == :datetime
            Arel.sql("INTERVAL '%s'" % v.inspect.sub(/s\Z/, '').upcase)
          end
        else
          return v
        end
      end

      def oracle_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            Arel.sql("INTERVAL '%s' DAY" % v.inspect.to_i)
          elsif @date_type == :datetime
            Arel.sql("INTERVAL '%s' SECOND" % v.to_i)
          end
        else
          v
        end
      end

      def mssql_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          v.parts[v.parts.keys[0]]
        else
          v
        end
      end

      def mssql_datepart(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          Arel.sql(v.parts.keys[0].to_s.singularize)
        else
          v
        end
      end

      private
      def convert(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, ActiveSupport::Duration
          object
        when Integer
          object.days
        when DateTime, Time, Date
          raise(ArgumentError, "#{object.class} can not be converted to Integer")
        when String
          Arel::Nodes.build_quoted(object)
        else
          raise(ArgumentError, "#{object.class} can not be converted to Integer")
        end
      end
    end

    class DateSub < Function #difference entre colonne date et date string/date
      RETURN_TYPE = :integer

      def initialize(expr)
        super [expr.first, convert_number(expr[1])]
      end

      def convert_number(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, Integer
          object
        when String
          object.to_i
        else
          raise(ArgumentError, "#{object.class} can not be converted to Number")
        end
      end

    end

  end
end
