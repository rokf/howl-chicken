-- built upon the Lisp bundle

import command from howl
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
    process = Process {
      cmd: "chicken-doc -c #{egg}"
      read_stdout: true
    }
    rtxt = process.stdout\read_all!
    items = [{identifier, usage, :egg} for identifier,usage in string.gmatch(rtxt, "([^%s]+)%s+([^\n\r]+)\r?\n")]
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
    process = Process { cmd: "chicken-doc -i #{s.selection.egg} #{s.selection[1]}", read_stdout: true }
    buf = howl.Buffer howl.mode.by_name('default')
    buf.text = process.stdout\read_all!
    howl.app.editor\show_popup BufferPopup(buf), { position: 1 }
}

-- autocomplete with chicken-doc -m ctx
class ChickenCompleter
  complete: (ctx) =>
    print ctx.word
    process = Process cmd: "chicken-doc -m #{ctx.word}", read_stdout: true
    process\wait!
    if process.successful
      return [id for id in string.gmatch process.stdout\read_all!, "%([a-z%d%-%?%!]+%s+([a-z%d%-%?%!]+)%)%s+" ]
    else return {}

howl.completion.register name: 'chicken_completer', factory: ChickenCompleter

command.register {
  name: 'chicken-doc'
  description: 'Show documentation for the current context'
  input: () ->
    context = howl.app.editor.current_context
    sContext = [item for item in string.gmatch(context.prefix, "[%w%d%-%?%!]+")]
    uContext = sContext[#sContext]
    process = Process { cmd: "chicken-doc -f #{uContext}",  read_stdout: true }
    received_txt = process.stdout\read_all!
    items = [{:line,line} for line in string.gmatch(received_txt, "%(([a-z%d%-%?%!%s]+)%)%s+")]
    if #items == 1 then return { selection: { line: items[1].line } }
    return howl.interact.select { :items, columns: { {header: 'Line'} } }
  handler: (ln) ->
    process = Process { cmd: "chicken-doc -i #{ln.selection.line}", read_stdout: true }
    received_txt = process.stdout\read_all!
    buf = howl.Buffer howl.mode.by_name('default')
    buf.text = received_txt
    howl.app.editor\show_popup BufferPopup buf
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
