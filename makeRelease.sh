#!/bin/sh
rm -rf release
rm jointro-tsa.zip
mkdir release
cp -v jointro-tsa.prg release/
cp -v nfo/jointro-tsa.nfo release/
cp -v res/screenshot.png release/
cp -r -v src release/
cd release
zip -r ../jointro-tsa.zip ./
cd ..
