require "spec_helper"
require "kusuri/sql/fragment"

describe Kusuri::Sql::Fragment do
    let(:term) { double }

    let(:fragment) { Kusuri::Sql::Fragment.new(term) }

    %w(select from join where group having order).each do |name|
        context "##{name}" do
            it "chains" do
                expect(fragment.send(name, "a")).to be(fragment)
            end

            it "default" do
                expect(fragment.clause(name)).to eq([])
            end

            it "single argument" do
                fragment.send(name, "a")
                expect(fragment.clause(name)).to eq(%w(a))
            end

            it "multiple invocations" do
                fragment.send(name, "a").send(name, "b")
                expect(fragment.clause(name)).to eq(%w(a b))
            end

            if(%w(where having).include?(name))
                it "preserves duplicates" do
                    fragment.send(name, "a").send(name, "b").send(name, 'a')
                    expect(fragment.clause(name)).to eq(%w(a b a))
                end

                it "bound variables" do
                    fragment.send(name, "a = ?", 1)
                    expect(fragment.clause(name)).to eq([ "a = ?" ])
                    expect(fragment.binds(name)).to eq([ 1 ])
                end

                it "hash argument" do
                    fragment.send(name, a: 1)
                    expect(fragment.clause(name)).to eq([ "a = ?" ])
                    expect(fragment.binds(name)).to eq([ 1 ])
                end

                it "multiple invocations with bound variables" do
                    fragment.send(name, "a = ?", 1)
                    fragment.send(name, "b = ?", 2)
                    expect(fragment.clause(name)).to eq([ "a = ?", 
                        "b = ?" ])
                    expect(fragment.binds(name)).to eq([ 1, 2 ])
                end

                it "requires the same number of binds and placeholders" do
                    expect(lambda { fragment.send(name, "a", 1) }).to \
                        raise_error(ArgumentError)
                end
            else
                it "removes duplicates" do
                    fragment.send(name, "a").send(name, "b").send(name, 'a')
                    expect(fragment.clause(name)).to eq(%w(a b))
                end

                it "multiple arguments" do
                    fragment.send(name, "a", "b")
                    expect(fragment.clause(name)).to eq(%w(a b))
                end

                it "resets" do
                    fragment.send(name, "a").send(name, nil)
                    expect(fragment.clause(name)).to eq([])
                end
            end
        end
    end

    context "#new predicates from term" do
        it "#and?" do
            term.stub(:and?).and_return(true)
            expect(term).to be_and
            expect(fragment).to be_and
        end

        it "#or?" do
            term.stub(:or?).and_return(true)
            expect(term).to be_or
            expect(fragment).to be_or
        end

        it "#not?" do
            term.stub(:not?).and_return(true)
            expect(term).to be_not
            expect(fragment).to be_not
        end

        it "not #and?" do
            term.stub(:and?).and_return(false)
            expect(term).to_not be_and
            expect(fragment).to_not be_and
        end

        it "not #or?" do
            term.stub(:or?).and_return(false)
            expect(term).to_not be_or
            expect(fragment).to_not be_or
        end

        it "not #not?" do
            term.stub(:not?).and_return(false)
            expect(term).to_not be_not
            expect(fragment).to_not be_not
        end
    end

    context "#operator" do
        before(:each) { term.stub(:not?).and_return(false) }

        it "equal to" do
            term.stub(:operator).and_return(:eq)
            expect(fragment.operator).to eq('=')
        end

        it "greater than" do
            term.stub(:operator).and_return(:gt)
            expect(fragment.operator).to eq('>')
        end

        it "less than" do
            term.stub(:operator).and_return(:lt)
            expect(fragment.operator).to eq('<')
        end
        
        it "greater than or equal to" do
            term.stub(:operator).and_return(:gte)
            expect(fragment.operator).to eq('>=')
        end

        it "less than or equal to" do
            term.stub(:operator).and_return(:lte)
            expect(fragment.operator).to eq('<=')
        end

        context "not?" do
            before(:each) { term.stub(:not?).and_return(true) }

            it "equal to" do
                term.stub(:operator).and_return(:eq)
                expect(fragment.operator).to eq('!=')
            end

            it "greater than" do
                term.stub(:operator).and_return(:gt)
                expect(fragment.operator).to eq('<=')
            end

            it "less than" do
                term.stub(:operator).and_return(:lt)
                expect(fragment.operator).to eq('>=')
            end
            
            it "greater than or equal to" do
                term.stub(:operator).and_return(:gte)
                expect(fragment.operator).to eq('<')
            end

            it "less than or equal to" do
                term.stub(:operator).and_return(:lte)
                expect(fragment.operator).to eq('>')
            end
        end
    end

    context "#sql" do
        it "having" do
            fragment.having('count(B.c) < 10')
            expect(fragment.sql).to match_ignoring_whitespace """
                having count(B.c) < 10"""
        end

        it "where" do
            fragment.where('B.c < 10')
            expect(fragment.sql).to match_ignoring_whitespace """
                where B.c < 10"""
        end

        it "select" do
            fragment.select('a')
            expect(fragment.sql).to match_ignoring_whitespace """
                select a"""
        end

        it "from" do
            fragment.from('table')
            expect(fragment.sql).to match_ignoring_whitespace """
                from table"""
        end

        it "join" do
            fragment.join('left join A on B')
            expect(fragment.sql).to match_ignoring_whitespace """
                left join A on B"""
        end

        it "group" do
            fragment.group('A')
            expect(fragment.sql).to match_ignoring_whitespace """
                group by A"""
        end

        it "order" do
            fragment.order('A')
            expect(fragment.sql).to match_ignoring_whitespace """
                order by A"""
        end

        it "limit" do
            fragment.limit(10)
            expect(fragment.sql).to match_ignoring_whitespace """
                limit 10"""
        end

        it "offset" do
            fragment.offset(10)
            expect(fragment.sql).to match_ignoring_whitespace """
                offset 10"""
        end

        it "full query" do
            fragment.select('a').from('A') \
                .join('left join B on B.a_id = A.id') \
                .where('A.a > 1').where('B.b < 1').group('a') \
                .having('count(B.c) < 10').limit(10).offset(20)
            expect(fragment.sql).to match_ignoring_whitespace(<<-END)
                select a from A
                left join B on B.a_id = A.id
                where (A.a > 1 and B.b < 1)
                group by a having count(B.c) < 10
                limit 10 offset 20
            END
        end

        pending "replaces placeholders for bind variables"
    end

    context "#sql_binds" do
        it "where" do
            fragment.where(a: 1, b: 2)
            fragment.sql_binds.should == [ 1, 2 ]
        end

        it "having" do
            fragment.having(a: 1, b: 2)
            fragment.sql_binds.should == [ 1, 2 ]
        end

        it "both" do
            fragment.where(a: 1, b: 2)
            fragment.having(a: 3, b: 4)
            fragment.sql_binds.should == [ 1, 2, 3, 4 ]
        end
    end

    context "#chunk_by_predicate" do
        def chunking(fragments)
            fragments_with_predicates = fragments.map do |fragment|
                fragment.stub(:and?).and_return(fragment == 'and')
                fragment
            end

            chunks = Kusuri::Sql::Fragment.chunk_by_predicate( \
                fragments_with_predicates)
            chunks.map { |c| "(#{c.join(" ")})" }.join(" ")
        end

        it "empty set" do
            expect(chunking([])).to eq("")
        end

        it "consecutive or-groups" do
            expect(chunking(%w(or or or))).to eq("(or or or)")
        end

        it "consecutive and-groups" do
            expect(chunking(%w(and and and))).to eq("(and and and)")
        end

        it "and-ed or-groups" do
            expect(chunking(%w(or or or and or or or))).to \
                eq("(or or or) (and or or or)")
        end

        it "or-ed and-groups" do
            expect(chunking(%w(and and and or and and and))).to \
                eq("(and and) (and or) (and and and)")
        end

        it "mix of everything" do
            expect(chunking(%w(and or and and and and or or or and or and))) \
                .to eq("(and or) (and and and) (and or or or) (and or) (and)")
        end
    end

    context "#reduce" do
        let(:and_term) do 
            result = Object.new
            result.stub(:and?).and_return(true)
            result.stub(:or?).and_return(false)
            result
        end

        let(:or_term) do 
            result = Object.new
            result.stub(:and?).and_return(false)
            result.stub(:or?).and_return(true)
            result
        end

        %w(where having).each do |name|
            context(name) do
                let(:klass) { Kusuri::Sql::Fragment }

                it "alpha and beta" do
                    alpha = klass.new(and_term).send(name, 'alpha')
                    beta = klass.new(and_term).send(name, 'beta')
                    result = klass.reduce([ alpha, beta ])
                    result.should be_a(klass)
                    expect(result.sql).to match_ignoring_whitespace """
                        #{name} (alpha and beta)"""
                end

                it "alpha or beta" do
                    alpha = klass.new(and_term).send(name, 'alpha')
                    beta = klass.new(or_term).send(name, 'beta')
                    result = klass.reduce([ alpha, beta ])
                    result.should be_a(klass)
                    expect(result.sql).to match_ignoring_whitespace """
                        #{name} (alpha or beta)"""
                end

                it "alpha and beta or gamma" do
                    alpha = klass.new(and_term).send(name, 'alpha')
                    beta = klass.new(and_term).send(name, 'beta')
                    gamma = klass.new(or_term).send(name, 'gamma')
                    result = klass.reduce([ alpha, beta,
                        gamma ])
                    result.should be_a(klass)
                    expect(result.sql).to match_ignoring_whitespace """
                        #{name} (alpha and (beta or gamma))"""
                end

                it "alpha and beta or gamma and delta" do
                    alpha = klass.new(and_term).send(name, 'alpha')
                    beta = klass.new(and_term).send(name, 'beta')
                    gamma = klass.new(or_term).send(name, 'gamma')
                    delta = klass.new(and_term).send(name, 'delta')
                    result = klass.reduce([ alpha, beta, gamma, delta ])
                    result.should be_a(klass)
                    expect(result.sql).to match_ignoring_whitespace """
                        #{name} (alpha and (beta or gamma) and delta)"""
                end

                it "alpha or beta and gamma or delta" do
                    alpha = klass.new(and_term).send(name, 'alpha')
                    beta = klass.new(or_term).send(name, 'beta')
                    gamma = klass.new(and_term).send(name, 'gamma')
                    delta = klass.new(or_term).send(name, 'delta')
                    result = klass.reduce([ alpha, beta, gamma, delta ])
                    result.should be_a(klass)
                    expect(result.sql).to match_ignoring_whitespace """
                        #{name} ((alpha or beta) and (gamma or delta))"""
                end

                it "alpha and (beta or gamma or delta)" do
                    beta = klass.new(or_term).send(name, 'beta')
                    gamma = klass.new(or_term).send(name, 'gamma')
                    delta = klass.new(or_term).send(name, 'delta')
                    inner = klass.reduce([ beta, gamma, delta ])

                    scope = klass.new(and_term).send(name, 'scope')
                    result = klass.reduce([ scope, inner ])

                    result.should be_a(klass)
                    expect(result.sql).to match_ignoring_whitespace """
                        #{name} (scope and (beta or gamma or delta))"""
                end
            end
        end
    end

    context "#coerce" do
        pending "string"

        pending "integer"

        pending "float"

        pending "boolean"

        pending "date"
    end
end
