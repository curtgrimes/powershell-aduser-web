#!/usr/bin/env bash

npm run build

rm -rf ./release
mkdir -p ./release/tmp
cp -r dist release/tmp
cp server.ps1 release/tmp

cd ./release/tmp
bestzip ../$npm_package_name-$npm_package_version.zip *

cd ../..

rm -rf ./release/tmp