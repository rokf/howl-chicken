{:activities, :app, :mode, :sys, :interact, :Buffer} = howl
{:Process} = howl.io

class ChickenMode
  new: =>
    @lexer = bundle_load('chicken_lexer')
    @completers = { 'chicken_completer', 'in_buffer' }

  default_config:
    complete: 'manual'

  show_doc: (editor) =>
    unless sys.find_executable 'chicken-doc'
      log.warning 'Command chicken-doc not found'
      return

    successful, process = pcall Process, {
      cmd: "chicken-doc -f #{app.editor.current_context.word}"
      read_stdout: true
      read_stderr: true
    }

    unless successful
      log.error "Failed looking up the context: #{process}"
      return

    stdout, _ = activities.run_process { title: 'fetching docs with chicken-doc' }, process

    items = [l for l in string.gmatch stdout, "%(([a-z%d%-%?%!%s]+)%)%s+"]
    if #items == 0 then return
    ln = #items == 1 and { selection: items[1] } or interact.select { :items, columns: { {header: 'Line'} } }
    if ln == nil then return nil

    successful, process = pcall Process, {
      cmd: "chicken-doc -i #{ln.selection}"
      read_stdout: true
      read_stderr: true
    }

    unless successful
      log.error "Failed looking up docs: #{process}"
      return

    stdout, _ = activities.run_process { title: 'fetching docs for selected element' }, process
    unless stdout.is_empty
      buf = Buffer mode.by_name 'default'
      buf.text = stdout
      return buf

  structure: (editor) => -- which lines to show in the structure view
    [l for l in *editor.buffer.lines when l\match '^%s*%(define' or l\match '^%s*%(ns%s']
