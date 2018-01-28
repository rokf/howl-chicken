find_start = (line, opening) ->
  closing = {v, k for k, v in pairs opening}
  stack = {}
  last = nil

  while line
    s = line.text

    for i = #s, 1, -1
      c = s[i]
      if c == last
        if #stack == 1 and i == 1
          return line, i, c, 'even'

        stack[#stack] = nil
        last = stack[#stack]
      elseif opening[c] and not closing[c]
        return line, i, c, 'open'
      else
        starter = closing[c]
        if starter
          stack[#stack + 1] = starter
          last = starter

    line = line.previous_non_blank

class ChickenMode
  new: =>
    @lexer = bundle_load('chicken_lexer')
    @completers = { 'chicken_completer', 'in_buffer' }

  comment_syntax: ';'

  default_config:
    word_pattern: '[^][%s/.(){}"\']+'
    complete: 'manual'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
  }

  indent_for: (line, indent_level) =>
    indentation = 0
    prev_line = line.previous_non_blank

    if prev_line -- if there was something in the previous line, indent the same ammount
      indentation = prev_line.indentation

      start_line, col, brace, status = find_start(prev_line, @auto_pairs)
      if start_line
        if status == 'even'
          indentation = col - 1
        elseif status == 'open'
          if brace == '('
            prev_char = start_line[col - 1]
            if prev_char == "`" or prev_char == "'" -- quoted form
              indentation = col + indent_level - 2
            else
              indentation = col + indent_level - 1
          else -- [ {
            indentation = col

        -- respect the indentation of the previous line if
        -- it's different from the form start
        if start_line.nr < prev_line.nr and prev_line.indentation < indentation
          indentation = prev_line.indentation

    indentation

  structure: (editor) => -- which lines to show in the structure view
    buffer = editor.buffer
    lines = {}
    patterns = { -- if it maches, it shows up under the structure
      '^%s*%(define'
      '%s*%(ns%s'
    }

    for line in *buffer.lines
      for pattern in *patterns
        if line\match pattern
          table.insert lines, line
          break

    lines
