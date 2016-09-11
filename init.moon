-- built uppon the Lisp bundle

import command from howl
import config from howl
import Process from howl.io -- to run external commands
import BufferPopup from howl.ui -- for docs
import execute from howl.io.Process

command.register({
  name: 'csc'
  description: "CHICKEN compiler"
  input: () ->
    howl.app.editor.buffer.file
  handler: (filename) ->
    howl.command.run(string.format("project-exec csc %s", filename))
})

command.register({
  name: 'chicken-doc-children'
  description: 'Pass the egg name/sequence and get children'
  input: () ->
    process = Process({
      cmd: string.format("chicken-doc -c %s", howl.interact.read_text title:'Which egg?', prompt:'egg:')
      read_stdout: true
    })
    rTxt = process.stdout\read_all! -- read all text
    print('rTxt', rTxt)
    items = {}
    for line in string.gmatch(rTxt, "(.-)\r?\n") -- split into lines
      table.insert(items, {
        line
        line: line
      })
    if #items == 0
      return howl.interact.select({
        items: {
          'empty'
          line: 'empty'
        }
        columns: {
          {header: 'Line'}
        }
      })
    return howl.interact.select({
      :items
      columns: {
        {header: 'Line'}
      }
    })
  handler: (ln) ->
    print(ln.selection.line)
})

command.register({
  name: 'chicken-doc'
  description: 'Show CHICKEN documentation for current context'
  input: () ->
    context = howl.app.editor.current_context
    sContext = {}
    print(context.prefix)
    for item in string.gmatch(context.prefix, "[%w%d%-%?]+") -- split into words
      table.insert(sContext, item)
    uContext = sContext[#sContext] -- get the last one
    print(uContext) -- print chosen context
    process = Process({
      cmd: string.format("chicken-doc -f %s", uContext)
      read_stdout: true
    })
    rTxt = process.stdout\read_all! -- read all text
    print('rTxt', rTxt)
    items = {}
    -- for lib, proc in string.gmatch(rTxt, "%(([%w%d%-]+)%s+([%w%d%-%?]+)%)")
    for line in string.gmatch(rTxt, "%(([a-z%d%-%?%s]+)%)%s+")
      table.insert(items, {
        line
        line: line
      })
    return howl.interact.select({
      :items
      columns: {
        {header: 'Line'}
      }
    })
  handler: (ln) ->
    -- library = ln.selection.lib
    -- procedure = ln.selection.proc
    process = Process({
      -- cmd: string.format("chicken-doc -i %s %s", library, procedure)
      cmd: string.format("chicken-doc -i %s", ln.selection.line)
      read_stdout: true
    })
    rTxt = process.stdout\read_all! -- read all text
    buf = howl.Buffer howl.mode.by_name('default') -- do popup
    buf.text = rTxt
    howl.app.editor\show_popup BufferPopup buf
})

howl.bindings.push({
  editor:
    ctrl_q: (editor) ->
      if howl.app.editor.buffer.mode.name == "chicken"
        howl.command.run 'chicken-doc'
      else
        howl.command.run 'show-doc-at-cursor'
})

mode_reg =
  name: 'chicken'
  extensions: { 'scm' }
  create: -> bundle_load('chicken_mode')!

howl.mode.register mode_reg

unload = ->
  howl.mode.unregister 'chicken'
  command.unregister 'chicken-doc'
  command.unregister 'chicken-doc-children'

return {
  info:
    author: 'Rok Fajfar',
    description: 'CHICKEN mode',
    license: 'MIT',
  :unload
}
