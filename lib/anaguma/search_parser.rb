# encoding: utf-8

require 'treetop'
require 'polyglot'
require 'anaguma/search'

module Anaguma
    module Search
        class Group < Treetop::Runtime::SyntaxNode
            include Enumerable

            def group?
                true
            end

            def predicate
                predicate = find_node(actual_root) { |node| 
                    node.is_a?(Predicate) and (not node.not?) }
                (predicate.nil? or predicate.and?) ? :and : :or
            end

            def each
                traverse(actual_root) do |node|
                    yield(node) if (node.is_a?(Term) or node.is_a?(Group)) 
                end
            end

            def to_s
                "(#{inject([ predicate ]) { |m, n| m.push(n) }.join(' ')})"
            end

            private

            def actual_root
                return(self) if (find_node(self) { |e| e.is_a?(Term) })
                subgroups = traverse(self) { |e| e.is_a?(Group) }
                return(self) unless (subgroups.count == 1)
                subgroups.first
            end

            def find_node(root = nil, &block)
                root ||= actual_root
                return(root) if yield(root)
                root.nonterminal? and root.elements.each do |node|
                    next if node.is_a?(Group)
                    result = find_node(node, &block) and return(result)
                end
                nil
            end

            def traverse(root, &block)
                return([]) unless root.nonterminal?
                root.elements.inject([]) do |result, node|
                    next(result.push(node)) if yield(node)
                    next(result) if node.is_a?(Group)
                    next(result) if node.is_a?(Term)
                    result.concat(traverse(node, &block))
                end
            end
        end

        class Term < Treetop::Runtime::SyntaxNode
            OPERATORS = { "<" => :lt, ">" => :gt, "<=" => :lte, ">=" => :gte,
                ":" => :eq, "~" => :like }
            INVERSES = { "<" => :gte, ">" => :lte, "<=" => :gt, ">=" => :lt,
                ":" => :ne, "~" => :notlike }

            def group?
                false
            end

            def field
                _field.is_a?(Field) ? _field.name : nil
            end

            def operator
                infix = _field.is_a?(Field) ? _field.infix : ":"
                return(OPERATORS[infix]) unless negated?
                INVERSES[infix]
            end

            def value
                _value.content.to_s
            end

            def quotes
                content = _value.content
                return("") unless content.is_a?(QuotedString)
                "#{content.left}#{content.right}"
            end

            def quoting
                content = _value.content
                return(:none) unless content.is_a?(QuotedString)
                return(:single) if content.left == "'"
                return(:double) if content.left == "\""
            end

            def negated?
                prefix and prefix.nonterminal? and prefix.not?
            end

            def text
                text_value.strip
            end

            def to_s
                content = _value.content
                quoted_value = "#{content.left}#{value}#{content.right}"
                "#{negated? ? "!" : ""}#{field}:#{operator}:#{quoted_value}"
            end
        end

        class Predicate < Treetop::Runtime::SyntaxNode
            def content
                text_value.strip.downcase
            end

            def and?
                (content == 'and') or (content == '&&')
            end

            def not?
                (content == 'not') or (content == '!')
            end
        end

        class Field < Treetop::Runtime::SyntaxNode
            def infix
                _infix.text_value.strip
            end

            def name
                _name.text_value.strip
            end
        end

        class Value < Treetop::Runtime::SyntaxNode
        end

        class QuotedString < Treetop::Runtime::SyntaxNode
            def to_s
                @_cached ||= content.text_value.gsub( \
                    /\\(#{quote(left)}|#{quote(right)})/, '\1')
            end

            def left
                _left.text_value
            end

            def right
                _right.text_value
            end

            private

            def quote(value)
                Regexp.quote(value)
            end
        end

        class UnquotedString < Treetop::Runtime::SyntaxNode
            def to_s
                text_value.tr('\'"', '')
            end

            def left
                ""
            end

            def right
                ""
            end
        end
    end
end
