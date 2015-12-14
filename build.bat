rmdir /S /Q dist
mkdir dist
"c:\Program Files\7-Zip\7z.exe" a -tzip dist/game.love ./*.lua base/* game/*
xcopy "c:\Program Files (x86)\LOVE\*.dll" dist
copy /b "c:\Program Files (x86)\LOVE\love.exe"+dist\game.love dist\game.exe
del dist\game.love
cd dist
"c:\Program Files\7-Zip\7z.exe" a -tzip game.zip *
cd ..
pause