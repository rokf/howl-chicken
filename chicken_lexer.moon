howl.util.lpeg_lexer ->

  expr_span = (start_pat, end_pat) ->
    start_pat * ((V'sexpr' + P 1) - end_pat)^0 * (end_pat + P(-1))

  comment = capture 'comment', any {
    span(';', eol),
    '#|' * scan_to('|#')^-1,
    P('#;') * P { 'sexpr', sexpr: expr_span('(',')') },
    span('#!' * (blank^1 + '\\'),eol)
  }

  dq_string = capture 'string', span('"', '"', P'\\')
  number = capture 'number', digit^1 * alpha^-1

  delimiter = any { space, S'/.,(){}[]^#' }

  dorc = any { delimiter, P':' }

  name = complement(dorc)^1
  identifier = capture 'identifier', name
  keyword = capture 'constant', any {
    P':' * name, --  * P':'^0
    P'#:' * name,
    name * P':'
  }

  fcall = sequence {
    '(',
    capture 'function', complement(delimiter)^1
  }

  -- span("#!" * (blank^1 + S("\\")), eol), -- bang
  -- P('#!') * ('optional' + 'rest' + 'key' + 'eof'),
  specials = capture 'special', any {
    word({ '#t', '#f' }) * #delimiter^1, -- booleans
    word({ '#cs', '#ci' }) * #delimiter^1, -- case sensitivity
    S('\'') * name,
    line_start * '#>' * scan_to('<#')^-1 -- foreign_declare
  }

  any {
    dq_string,
    comment,
    number,
    fcall,
    keyword,
    specials,
    identifier,
  }
