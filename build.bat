@echo off
set release=Release
IF not exist %release% (mkdir %release%)

odin run main.odin -out:./release/tin_lib.exe

