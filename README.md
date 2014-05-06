# An ApportablePlugin

A simple plugin to run apportable commands from inside Xcode as a starting point. To use, build the project 
which will linstall to the correct directory and then restart Xcode. Open an apportable project and use 
the new menu at the end of Xcode's "Product" menu to run the apportable debug/load/log/kill commands. 
You can type into the console windows opened or type control-c to interrupt the command. The "apportable 
log" window can be filtered by entering a regular expression. Windows close automatically on sucess.

### Live Coding

The plugin now also supports live coding where you can make changes the implementation of a running
program. The main.m of the project project must first have been slightly patched by using the menu item
"Product/Apportable/Prepare". After this, when the program is running or being debugged,
changes to the current selected file can be applied using the "Apportable/Patch" command. As this
requires a debugging connection, if one is not already open the plugin will attach to the program.

Live Coding works by #importing the changed class into a small stub of code which lists the classes
being loaded which is compiled and the resulting shared library copied to phone. gdb is then messaged 
by the plugin to call [APLiveCoding inject:"/data/local/tmp/APLiveCodingN.so"] which loads and calls the 
stub in the shared library. This registers any selector references and "swizzles" the new implementations 
onto the original class. Remember to "Apportable/Prepare" your project to make APLiveCoding available.

### Demo App

A small demo app is included in the plugin which can be opened using the "Apportable/Demo" menu item.
Run the applpication using "Apportable/Load" and edit the file "INRoseView.m" and type ^X to see how 
changing the various hard coded values affects the displayed appearance. This will open a window to
"just_attach" to the process to load the changes using gdb commands. Do not close this window if 
you want to make subseqent changes as patching only works in the just debug/attach window opened.

### MIT License

Copyright (C) 2014 John Holdsworth

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
