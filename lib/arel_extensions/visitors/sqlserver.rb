module ArelExtensions
  module Visitors
    Arel::Visitors::SQLServer.class_eval do
      def visit_ArelExtensions_Nodes_StringToDate(o, collector)
        collector << "CAST("
        collector = visit Arel::Nodes::Quoted.new(o.left), collector
        collector << " AS datetime)"
        collector
      end

      def visit_ArelExtensions_Nodes_DateTruncate(o, collector)
        date_unit = Arel::Nodes::SqlLiteral.new(o.left)
        collector << "DATEADD("
        collector = visit date_unit, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector << " DATEDIFF("
        collector = visit date_unit, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector << " 0"
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector << Arel::Visitors::MSSQL::COMMA
        collector << " 0)"
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        if o.precision == 'year' || o.precision == 'month'
          month_year_date_diff(o, collector)
        else
          default_date_diff(o, collector)
        end
      end

      def month_year_date_diff(o, collector)
        collector << "DATEDIFF(#{o.precision}"
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ')'
        collector << ' + '
        collector << "(DATEDIFF(millisecond, DATEADD(#{o.precision}, DATEDIFF(#{o.precision}, 0, "
        collector = visit o.left, collector
        collector << "), 0), "
        collector = visit o.left, collector
        collector << ")"
        collector << " - "
        collector << "DATEDIFF(millisecond, DATEADD(#{o.precision}, DATEDIFF(#{o.precision}, 0, "
        collector = visit o.right, collector
        collector << "), 0), "
        collector = visit o.right, collector
        collector << ")"
        collector << ") / CAST(#{second_unit_multiplier(o.precision)} AS float)"
        collector
      end

      def default_date_diff(o, collector)
        collector << "DATEDIFF(second"
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ") / CAST(#{second_unit_multiplier(o.precision)} AS float)"
        collector
      end

      def second_unit_multiplier(unit)
        case unit
        when 'year'
          366 * 24 * 60 * 60
        when 'month'
          31 * 24 * 60 * 60
        when 'week'
          7 * 24 * 60 * 60
        when 'day'
          24 * 60 * 60
        when 'hour'
          60 * 60
        when 'minute'
          60
        when 'second'
          1
        end
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "DATEADD("
        collector << o.mssql_datepart(o.right)
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.mssql_value(o.right), collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_CurrentDate(o, collector)
        collector << "GETDATE()"
        collector
      end

      def visit_ArelExtensions_Nodes_Cast o, collector
        if o.as_attr.to_sym == :boolean
          if o.left.value
            collector << "1 = 1"
          else
            collector << "1 != 1"
          end
        else
          collector << "CAST("
          collector = visit o.left, collector
          collector << " AS "
          case o.as_attr.to_sym
          when :string
            as_attr = Arel::Nodes::SqlLiteral.new('varchar')
          when :time
            as_attr = Arel::Nodes::SqlLiteral.new('time')
          when :number
            as_attr = Arel::Nodes::SqlLiteral.new('int')
          when :datetime
            as_attr = Arel::Nodes::SqlLiteral.new('datetime')
          when :binary
            as_attr = Arel::Nodes::SqlLiteral.new('binary')
          else
            as_attr = Arel::Nodes::SqlLiteral.new(o.as_attr.to_s)
          end
          collector = visit as_attr, collector
          collector << ")"
          collector
        end
        collector
      end

      def visit_Arel_Nodes_WithRecursive o, collector
        collector << "WITH "
        inject_join o.children, collector, Arel::Visitors::MSSQL::COMMA
      end
    end
  end
end
