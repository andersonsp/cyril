
## OpenGL

### Shader Demos

https://github.com/fsole/Dodo3D



## Blender python

### Drop into interactive mode

`__import__('code').interact(local=dict(globals(), **locals()))`


### Pass arguments to the python script on the command line

Blender will ignore all arguments after: --
(double dash with no arguments, as documented in the --help message)

```python
import sys
argv = sys.argv
argv = argv[argv.index("--") + 1:]  # get all args after "--"

print(argv)  # --> ['example', 'args', '123']
```

Execute like this:

`blender --background test.blend --python mytest.py -- example args 123`




## Makefile

### Detect OS

https://gist.github.com/sighingnow/deee806603ec9274fd47



## MacOS

### App Bundles

OSX will not launch an application by just launching the executable file
it is necessary to create an application bundle, which is just a directory with a name ending in '.app'
(this article)[https://mathiasbynens.be/notes/shell-script-mac-apps] and
(stackoverflow/building-osx-app-bundle)[https://stackoverflow.com/questions/1596945/building-osx-app-bundle]
helped develop the tool I'm using for the project.

The required structure of the App Bundle is as follows:
```
foo.app/
    Contents/
        Info.plist
        MacOS/
            foo
        Resources/
            foo.icns
```

Executable dynamic libs and data dependencies go in the directory `foo.app/Contents/MacOS/`

When you start your app the current directory will be the directory above where the application is located.
For example: If you place the foo.app in the /Applcations folder
then the current directory when you launch the app will be the /Applications folder.
Not the /Applications/foo.app/Contents/MacOS/ as you might expect.

You can alter your app to account for this, or you can use this magic little launcher script
that will change the current directory and launch your app.


```sh
#!/bin/bash
cd "${0%/*}"
./foo
```

Make sure you adjust the Info.plist file so that CFBundleExecutable points to the launch script
and not to the previous executable.

To launch the Bundle from the CLI, we use the following command: `open -a ./the/bundle.app`



