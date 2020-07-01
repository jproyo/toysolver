#!/bin/bash
export CABALVER=1.22
export GHCVER=7.10.3

sudo add-apt-repository -y ppa:hvr/ghc
sudo apt-get update

sudo apt-get install cabal-install-$CABALVER ghc-$GHCVER
export PATH=/opt/ghc/$GHCVER/bin:/opt/cabal/$CABALVER/bin:~/.cabal/bin:$PATH

sudo apt-get install happy-1.19.4 alex-3.1.3
export PATH=/opt/alex/3.1.3/bin:/opt/happy/1.19.4/bin:$PATH

cabal sandbox init
cabal update
cabal install --only-dependencies
#cabal configure --disable-shared --ghc-options="-static -optl-static -optl-pthread"
cabal configure -fLinuxStatic -fForceChar8
cabal build

PKG=toysmt-smtcomp`date +%Y`-`date +%Y%m%d`-`git rev-parse --short HEAD`
rm -r $PKG
cp -a misc/smtcomp $PKG
cp dist/build/toysmt/toysmt $PKG/bin
cd $PKG
tar zcf ../$PKG.tar.gz . --owner=sakai --group=sakai
