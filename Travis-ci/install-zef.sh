#!/usr/bin/env sh

set -vx

# Install zef

#/bin/ls -lR

cd ${TRAVIS_BUILD_DIR}/Travis-ci

if [ ! -e zef ]
then

  git clone https://github.com/ugexe/zef.git
  cd zef
  perl6 -Ilib bin/zef install .
  rehash

else

  rehash
  zef update

fi

zef --/test install Config::TOML
zef --/test install MongoDB
zef --depsonly install .

exit 0
