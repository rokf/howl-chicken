howl.util.lpeg_lexer ->

  expr_span = (start_pat, end_pat) ->
    start_pat * ((V'sexpr' + P 1) - end_pat)^0 * (end_pat + P(-1))

  comment = capture 'comment', any {
    span(';', eol),
    '#|' * scan_to('|#')^-1,
    P('#;') * P { 'sexpr', sexpr: expr_span('(',')') }
  }

  operator = capture 'operator', S'/.%^#,(){}[]'
  dq_string = capture 'string', span('"', '"', P'\\')
  number = capture 'number', digit^1 * alpha^-1

  foreign_declare = capture 'special', '#>' * scan_to('<#')^-1

  delimiter = any { space, S'/.,(){}[]^#' }

  dorc = any { delimiter, P':' }

  name = complement(dorc)^1

  identifier = capture 'identifier', name
  keyword = capture 'constant', any {
    P':' * name, --  * P':'^0
    P'#:' * name,
    name * P':'
  }

  fcall = capture('operator', P'(') * capture('function', complement(delimiter))^1

  specials = capture 'special', any {
    word({ '#t', '#f' }) * #delimiter^1, -- booleans
    word({ '#cs', '#ci' }) * #delimiter^1, -- case sensitivity
    span("#!",eol), -- bang
    S('\'') * name
  }

  any {
    dq_string,
    comment,
    foreign_declare,
    number,
    fcall,
    keyword,
    specials,
    identifier,
    operator
  }
