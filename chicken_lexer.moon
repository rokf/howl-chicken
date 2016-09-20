howl.util.lpeg_lexer ->

  comment_span = (start_pat, end_pat) ->
    start_pat * ((V'comment' + P 1) - end_pat)^0 * (end_pat + P(-1))

  nested_s = capture 'comment', P {
    'comment'

    comment: any {
      comment_span P'(',')'
    }
  }

  expression_comment = capture('comment', P'#;') * nested_s

  comment = capture 'comment', span(';', eol)
  block_comment = capture 'comment', '#|' * scan_to('|#')^-1
  operator = capture 'operator', S'/.%^#,(){}[]'
  dq_string = capture 'string', span('"', '"', P'\\')
  number = capture 'number', digit^1 * alpha^-1

  foreign_declare = capture 'special', '#>' * scan_to('<#')^-1

  delimiter = any { space, S'/.,(){}[]^#' }

  dorc = any { delimiter, P':' }

  -- name = complement(delimiter)^1
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
    block_comment,
    foreign_declare,
    expression_comment,
    number,
    fcall,
    keyword,
    specials,
    identifier,
    operator
  }
