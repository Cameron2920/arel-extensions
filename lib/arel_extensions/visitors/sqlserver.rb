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
        collector << if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
                       "DATEDIFF(#{o.precision}"
                     else
                       'DATEDIFF(day'
                     end
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ')'
        collector
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

      def visit_ArelExtensions_Nodes_Cast o, collector
        collector << "CAST("
        collector = visit o.left, collector
        collector << " AS "
        case o.as_attr
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

      def visit_Arel_Nodes_WithRecursive o, collector
        collector << "WITH "
        inject_join o.children, collector, Arel::Visitors::MSSQL::COMMA
      end
    end
  end
end
