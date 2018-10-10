#!/bin/bash
cd ./ui
npm run build

cd ../srv
gradle
gradle deps

cd ..
rm -r ./release/html
rm -r ./release/deps

mkdir ./release/html
mkdir ./release/deps

cp -r ./ui/dist/. ./release/html
cp ./srv/build/libs/deps/*.* ./release/deps
cp ./srv/build/libs/*.jar ./release