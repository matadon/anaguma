module Kusuri
    module Parser
        class Group < Treetop::Runtime::SyntaxNode
            include Enumerable

            def group?
                true
            end

            def predicate
                predicate = find(self) { |node| 
                    node.is_a?(Predicate) and (not node.not?) }
                (predicate.nil? or predicate.and?) ? :and : :or
            end

            def groups
                traverse(self) { |n| n.is_a?(Group) }
            end

            def terms
                traverse(self) { |n| n.is_a?(Term) }
            end

            def each
                traverse(self) { |node|
                    yield(node) if (node.is_a?(Term) or node.is_a?(Group)) }
            end

            private

            def find(root, &block)
                return(root) if yield(root)
                root.nonterminal? and root.elements.each do |node|
                    next if node.is_a?(Group)
                    result = find(node, &block) and return(result)
                end
                nil
            end

            def traverse(root, &block)
                return([]) unless root.nonterminal?
                root.elements.inject([]) do |result, node|
                    next(result.push(node)) if yield(node)
                    next(result) if node.is_a?(Group)
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
                return(OPERATORS[infix]) unless not?
                INVERSES[infix]
            end

            def value
                _value.content.to_s
            end

            def quoting
                content = _value.content
                return(:single) if content.is_a?(SingleQuotedString)
                return(:double) if content.is_a?(DoubleQuotedString)
                return(:none)
            end

            def not?
                prefix and prefix.nonterminal? and prefix.not?
            end

            def plaintext
                text_value.strip
            end

            def to_s
                content = _value.content
                quoted_value = "#{content.left}#{value}#{content.right}"
                "#{not? ? "!" : ""}#{field}:#{operator}:#{quoted_value}"
            end
        end

        class Predicate < Treetop::Runtime::SyntaxNode
            def content
                text_value.strip.downcase
            end

            def or?
                (content == 'or') or (content == '||')
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

        class SingleQuotedString < Treetop::Runtime::SyntaxNode
            def to_s
                content.text_value.gsub(/\\\'/, "'")
            end

            def left
                "'"
            end

            def right
                "'"
            end
        end

        class DoubleQuotedString < Treetop::Runtime::SyntaxNode
            def to_s
                content.text_value.gsub(/\\\"/, '"')
            end

            def left
                '"'
            end

            def right
                '"'
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
