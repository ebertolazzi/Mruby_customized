**Compilazione della libreria MRUBY**


**LINUX OSX**

Per compilare in OSX e linux basta digitare `rake`.
E' opportuno fare un 

`rake mruby:clean`

prima di compilare se ci sono problemi di compilazione.
Una volta compilata eseguire 

`rake mruby:copylib`

per copiare la libreria e gli header in `Libsources/os_mac`
o  `Libsources/os_linux`

**WINDOWS**

per comopilare la libreria su WINDOWS lanciare

`build_vs`

compilera la libreria per VS2013, VS2015 a 32 e 64 bit nel modo debug e release.
Le librerie e gli header verranno copiate nella directory

`C:\PINS`
