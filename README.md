
Intro
=====

A simple, basic HTTP/2 server that answers in two interlocked streams.
The goal is to test concurrency. 
If a client tries to pull just from one stream at a time, it will block. 


Compiling
=========

This is made in Haskell. If you don't have haskell installed, in Ubuntu is 
as easy as doing

    $ sudo add-apt-repository ppa:hvr/ghc
    $ sudo apt-get update
    $ sudo apt-get install ghc-7.8.3 cabal-install-1.22

Quoting the [documentation at the PPA](https://launchpad.net/~hvr/+archive/ubuntu/ghc/+index?batch=75&direction=backwards&memo=75), The packages install into `/opt/ghc/$VER/` so in order to use them, the easiest way is to bring a particular GHC version into scope by placing the respective 
`/opt/ghc/$VER/bin` folder early into the PATH environment variable.

To compile the program proper, clone this repository and in the cloned directory
do:

    $ cabal sandbox init
    $ cabal install --dependencies-only
    $ cabal build

You will find the program at `dist/build/lock-step-stransfer/lock-step-stransfer`, a hearty beast of 12 
Mb.

Running
=======

Do like this:

    $ dist/build/lock-step-stransfer/lock-step-stransfer

