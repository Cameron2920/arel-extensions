module ArelExtensions
  module Nodes
    class Coalesce < Function
      RETURN_TYPE = :string

      def initialize expr
        super(expr)
      end
    end
  end
end
