howl.util.lpeg_lexer ->

  expr_span = (start_pat, end_pat) ->
    start_pat * ((V'sexpr' + P 1) - end_pat)^0 * (end_pat + P(-1))

  comment = capture 'comment', any {
    span(';', eol),
    P'#|' * scan_to '|#',
    P'#;' * P { 'sexpr', sexpr: expr_span('(',')') },
    span('#!' * (blank^1 + '\\'), eol)
  }

  delimiter = any { space, P'\n', S'()[]' }
  -- delimiter = any { space, S'/.,(){}[]^#' }

  character = capture 'char', P'#\\' * (1 - delimiter)

  string = capture 'string', span '"', '"'

  number = capture 'number', word {
    digit^1 * P'/' * digit^1 -- rational
    P('-')^-1 * digit^1 * P'.' * digit^1 * (S'eE' * P('-')^-1 * digit^1)^-1 -- floating
    P('-')^-1 * digit^1 -- decimal
    P'#' * S'Bb' * S'01'^1 -- binary
    P'#' * S'Oo' * R('07')^1 -- octal
    P'#' * S'Xx' * R('AF','af','09')^1 -- hexadecimal
  }

  dorc = any { delimiter, P':' }

  name = complement(dorc)^1
  identifier = capture 'identifier', name

  keyword = capture 'constant', any {
    P':' * name,
    P'#:' * name,
    name * P':'
  }

  specials = capture 'special', any {
    word { '#t', '#f' }
    word { '#cs', '#ci' }
    S('\'') * name
    line_start * '#>' * scan_to('<#')
  }

  any {
    string,
    character,
    comment,
    number,
    keyword,
    specials,
    identifier
  }
