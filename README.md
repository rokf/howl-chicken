<p align="center"><img width="200" src="img.png"></p>

```
cd ~/.howl/bundles
git clone https://github.com/rokf/howl-chicken
```

The bundle contains a lexer, because *CHICKEN* has some minor syntax additions (compared to other Scheme
implementations).

This bundle provides autocomplete and inline documentation features,
which depend on `chicken-doc`.
Go to http://wiki.call-cc.org/eggref/4/chicken-doc for installation instructions.

There is a also a `chicken-doc-children` command which offers a selection
between identifiers contained in an egg or unit. On the selection
of an identifier its description is displayed.

You have to overwrite the `ctrl_q` key binding
(or whatever you have set for docs to show up)
for the documentation feature.

```
howl.bindings.push {
  editor = {
    ctrl_q = function (editor)
      if howl.app.editor.buffer.mode.name == "chicken" then
        howl.command.run('chicken-doc')
      else
        howl.command.run('show-doc-at-cursor')
      end
    end
  }
}
```

This example also shows why this has to be done. If you'd have multiple bundles changing the binding,
they would overwrite and only one binding would work at time (the last loaded/reloaded one).

Some code is copied from the `Lisp` bundle
contained within the `Howl` source.
It was written by *Nils Nordman* and is licensed under the **MIT** license.

Everything else (the stuff I've written) is also **MIT** licensed.
