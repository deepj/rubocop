# encoding: utf-8

module RuboCop
  module Cop
    module Style
      # This cop checks symbol literal syntax.
      #
      # @example
      #
      #   # bad
      #   :"symbol"
      #
      #   # good
      #   :symbol
      class SymbolLiteral < Cop
        MSG = 'Do not use strings for word-like symbol literals.'

        def on_sym(node)
          return unless node.source =~ /\A:["'][A-Za-z_]\w*["']\z/

          add_offense(node, :expression)
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.expression, node.source.delete(%q('")))
          end
        end
      end
    end
  end
end
