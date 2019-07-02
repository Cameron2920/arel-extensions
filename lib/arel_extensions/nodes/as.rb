module ArelExtensions
  module Nodes
    class As < Arel::Nodes::As

      def initialize left,right
        return super(left,right)
      end
    end

    class CTEAlias < Arel::Nodes::Node
      attr_accessor :table_name
      attr_accessor :column_names

      def initialize(table_name, column_names)
        @table_name = table_name
        @column_names = column_names
      end
    end
  end
end


