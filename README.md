<p align="center"><img width="200" src="img.png"></p>

#### Installation (Linux)

```
cd ~/.howl/bundles
git clone https://github.com/rokf/howl-chicken
```

#### Dependencies

This bundle provides autocomplete and inline documentation features, which depend on `chicken-doc`.
Go to http://wiki.call-cc.org/eggref/4/chicken-doc for installation instructions.

**Note:** chicken-doc has not yet been ported to chicken v5, this means that
autocomplete & documentation features won't work with the latest chicken scheme version

#### Commands

- **chicken-doc-children**

Offers a selection between egg/unit identifiers.
Displays a description of the selected identifier.

- **csi-pretty-eval**

Evaluates the selected expression
and displays the result in a popup buffer.

- **csc**

Compiles the current file with csc.
Requires the file to be in a Howl project.
