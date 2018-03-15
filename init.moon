-- built upon the Lisp bundle

import command, activities from howl
import Process from howl.io
import BufferPopup from howl.ui

command.register {
  name: 'csc'
  description: "Run csc"
  input: () -> howl.app.editor.buffer.file
  handler: (filename) -> howl.command.run("project-exec csc #{filename}")
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
      buf = howl.Buffer howl.mode.by_name('default')
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

command.register {
  name: 'chicken-doc'
  description: 'Show documentation for the current context'
  input: () ->
    successful, process = pcall Process, {
      cmd: "chicken-doc -f #{howl.app.editor.current_context.word}"
      read_stdout: true
      read_stderr: true
    }
    items = {}
    if successful
      stdout, _ = activities.run_process { title: 'fetching docs with chicken-doc' }, process
      items = [line for line in string.gmatch stdout, "%(([a-z%d%-%?%!%s]+)%)%s+"]
    if #items == 0 then return nil
    if #items == 1 then return { selection: items[1] }
    return howl.interact.select { :items, columns: { {header: 'Line'} } }
  handler: (ln) ->
    if ln == nil then return nil
    successful, process = pcall Process, {
      cmd: "chicken-doc -i #{ln.selection}"
      read_stdout: true
      read_stderr: true
    }
    if successful
      stdout, _ = activities.run_process { title: 'fetching docs for selected element in package' }, process
      if #stdout > 0
        buf = howl.Buffer howl.mode.by_name('default')
        buf.text = stdout
        howl.app.editor\show_popup BufferPopup(buf), { position:1 }
      else
        log.info "the element has no docs"
}

mode_reg =
  name: 'chicken'
  extensions: { 'scm' }
  create: -> bundle_load('chicken_mode')!

howl.mode.register mode_reg

unload = ->
  howl.mode.unregister 'chicken'
  command.unregister 'chicken-doc'
  command.unregister 'chicken-doc-children'
  howl.completion.unregister 'chicken_completer'

return {
  info:
    author: 'Rok Fajfar',
    description: 'CHICKEN mode',
    license: 'MIT',
  :unload
}
