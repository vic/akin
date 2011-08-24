require File.expand_path('../../lib/akin', __FILE__)

shared_context 'grammar' do

  def o(line = 0, column = 0)
    Akin::Grammar::Position.new(line, column)
  end
  
  def c(code, rule = :root, fail_on_error = false, *args)
    parser = Akin::Grammar.new(code)
    method = "_"+rule.to_s.gsub('-', '_hyphen_')
    args.push(o) if parser.method(method).arity > 0 && args.empty?
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
    n.shuffle.sexp if n
  end
end
