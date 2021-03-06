# encoding: utf-8

module RuboCop
  module Cop
    module Performance
      # This cop identifies unnecessary use of a regex where `String#end_with?`
      # would suffice.
      #
      # @example
      #   @bad
      #   'abc' =~ /bc\Z/
      #   'abc'.match(/bc\Z/)
      #
      #   @good
      #   'abc' =~ /ab/
      #   'abc' =~ /\w*\Z/
      class EndWith < Cop
        MSG = 'Use `String#end_with?` instead of a regex match anchored to ' \
              'the end of the string.'
        SINGLE_QUOTE = "'".freeze

        def_node_matcher :redundant_regex?, <<-END
          {(send $_ {:match :=~} (regexp (str $#literal_at_end?) (regopt)))
           (send (regexp (str $#literal_at_end?) (regopt)) {:match :=~} $_)}
        END

        def literal_at_end?(regex_str)
          # is this regexp 'literal' in the sense of only matching literal
          # chars, rather than using metachars like . and * and so on?
          # also, is it anchored at the end of the string?
          regex_str =~ /\A(?:[\w\s\-,"']|\\[.*?\[\]{}()|^$nt])+\\Z\Z/
        end

        def on_send(node)
          add_offense(node, :expression, MSG) if redundant_regex?(node)
        end

        def autocorrect(node)
          redundant_regex?(node) do |receiver, regex_str|
            receiver, regex_str = regex_str, receiver if receiver.is_a?(String)
            regex_str = regex_str[0..-3] # drop \Z anchor
            regex_str.gsub!(/\\([.*?\[\]{}()|^$])/, '\1')
            regex_str.gsub!('\n', "\n")
            regex_str.gsub!('\t', "\t")

            lambda do |corrector|
              new_source = receiver.source + '.end_with?(' +
                           escape(regex_str) + ')'
              corrector.replace(node.loc.expression, new_source)
            end
          end
        end

        def require_double_quotes?(string)
          string.inspect.include?(SINGLE_QUOTE) ||
            StringHelp::ESCAPED_CHAR_REGEXP =~ string ||
            string =~ /[\n\t]/
        end

        def escape(string)
          if require_double_quotes?(string)
            string.inspect
          else
            "'#{string}'"
          end
        end
      end
    end
  end
end
