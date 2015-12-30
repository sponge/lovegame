rmdir /S /Q dist
mkdir dist
"c:\Program Files\7-Zip\7z.exe" a -tzip dist/game.love ./*.lua base/* game/* Quickie/*
xcopy "c:\Program Files\LOVE\*.dll" dist
copy /b "c:\Program Files\LOVE\love.exe"+dist\game.love dist\game.exe
move dist\game.love c:\dropbox\game.love
del dist\game.love
cd dist
"c:\Program Files\7-Zip\7z.exe" a -tzip game.zip *
cd ..
move dist\game.zip c:\dropbox\game.zip
echo https://www.dropbox.com/s/bse3a6ao34apogn/game.zip?dl=0| clip
pause