#!/usr/bin/env sh

git clone https://gitlab.matrix.org/matrix-org/olm.git .olm --branch 3.1.3 --depth 1

cd .olm

cmake . -Bbuild

cmake --build build

mkdir -p ../lib-native

cp build/libolm.so* ../lib-native

cd ..

rm -rf .olm