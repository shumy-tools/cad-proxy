#!/bin/bash
cp ./srv/build/libs/*.jar ./release
cd ./release
./run.sh
cd ..
