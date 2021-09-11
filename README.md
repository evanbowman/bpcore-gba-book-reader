# bpcore-gba-book-reader

A sample app to demonstrate the BPCore gba engine's builtin unicode text system. main.lua consists of about 300 lines of code, which implements a functional (but certainly not feature-rich) ebook reader, which stores its state in SRAM (cartridge save data), so you can pick up where you left off. Bundled with the project, you'll find a very good book encoded in a non-ascii charset.

Features demonstrated in this example:
* Unicode text handling
* SRAM writes

To build the project, you just need to run build.lua, which requires an installation of lua 5.3.
