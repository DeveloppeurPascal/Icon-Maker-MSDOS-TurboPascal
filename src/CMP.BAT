@echo off
set code=mkicn
mkmsg mkicn
lha a c:\olf_soft\lzh\%code% mkicon.exe mkicn.msg cross.mou setup.cfg ..\divers\setdflt.exe ..\mkpal\standard.pal *.icn
set code=
echo on
