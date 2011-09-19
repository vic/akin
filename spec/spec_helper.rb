require File.expand_path('../../lib/akin', __FILE__)

shared_context 'grammar' do

  def c(code, rule = :root, fail_on_error = false, *args)
    parser = Akin::Grammar.new(code)
    method = "_"+rule.to_s.gsub('-', '_hyphen_')
    if parser.method(method).arity > 0 && args.empty?
      args.push(parser.ctx)
    end
    ok = parser.__send__(method, *args)
    parser.raise_error if fail_on_error && !ok
    ok && parser.result
  end

  def s(code, rule = :root, *args)
    n = c(code, rule, true, *args)
    n.sexp if n
  end

  def n(code, rule = :root, *args)
    n = c(code, rule, true, *args)
    Akin::Shuffle.new(Akin::Operator::Table.new).shuffle(n).sexp if n
  end
end
