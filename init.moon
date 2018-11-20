-- built upon the Lisp bundle

{:command, :activities, :app, :mode} = howl
{:Process} = howl.io
{:BufferPopup} = howl.ui

command.register
  name: 'csi-pretty-eval'
  description: "Run csi -P on selected expression"
  handler: ->
    s_text = app.editor.selection.text
    success, pco = pcall Process.open_pipe, {'csi', '-P', s_text}
    if not success
      log.error pco
      return
    stdout, stderr = activities.run_process { title: 'running csi -P on selection' }, pco
    txt = ""
    if #stdout ~= 0
      txt = stdout
    else
      txt = stderr
    buf = howl.Buffer mode.by_name 'default'
    buf.text = txt
    app.editor\show_popup BufferPopup buf

command.register {
  name: 'csc'
  description: "Compile file with csc"
  handler: ->
    filename = howl.app.editor.buffer.file
    if not filename then return
    proj = howl.Project.for_file(filename)
    if not proj
      log.warn 'needs a project'
      return
    howl.command.run("project-exec csc #{filename}")
}

command.register {
  name: 'chicken-doc-children'
  description: 'Get the contents of an egg or unit'
  input: () ->
    egg = howl.interact.read_text(title:'Which egg/unit?')
    successful, process = pcall Process, {
      cmd: "chicken-doc -c #{egg}"
      read_stdout: true
      read_stderr: true
    }
    items = {}
    if successful
      stdout, _ = activities.run_process { title: 'getting package content with chicken-doc' }, process
      items = [{identifier, usage, :egg} for identifier,usage in string.gmatch(stdout, "([^%s]+)%s+([^\n\r]+)\r?\n")]
    if #items == 0 then return {} -- nothing there
    return howl.interact.select {
      :items
      columns: {
        {header: 'Identifier', style:'bold'}
        {header: 'Usage'}
      }
    }
  handler: (s) ->
    if s.selection == nil then return {}
    successful, process = pcall Process, {
      cmd: "chicken-doc -i #{s.selection.egg} #{s.selection[1]}"
      read_stdout: true
      read_stderr: true
    }
    if successful
      stdout, _ = activities.run_process { title: 'getting details of the selected child' }, process
      buf = howl.Buffer mode.by_name 'default'
      buf.text = stdout
      howl.app.editor\show_popup BufferPopup(buf), { position: 1 }
}

-- autocomplete with chicken-doc -m ctx
class ChickenCompleter
  complete: (ctx) =>
    successful, process = pcall Process, {
      cmd: "chicken-doc -m #{ctx.word}"
      read_stdout: true
      read_stderr: true
    }
    if successful
      stdout, _ = activities.run_process { title: 'fetching completions with chicken-doc' }, process
      return [id for id in string.gmatch stdout, "%([a-z%d%-%?%!]+%s+([a-z%d%-%?%!]+)%)%s+" ]
    else return {}

howl.completion.register name: 'chicken_completer', factory: ChickenCompleter

mode.register
  name: 'chicken'
  extensions: { 'scm' }
  create: -> bundle_load('chicken_mode')!
  parent: 'lisp'

unload = ->
  mode.unregister 'chicken'
  command.unregister 'chicken-doc-children'
  command.unregister 'csi-pretty-eval'
  command.unregister 'csc'
  howl.completion.unregister 'chicken_completer'

return {
  info:
    author: 'Rok Fajfar',
    description: 'CHICKEN mode',
    license: 'MIT',
  :unload
}
