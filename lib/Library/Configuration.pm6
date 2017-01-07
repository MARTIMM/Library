use v6.c;

use Config::TOML;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;

#-------------------------------------------------------------------------------
unit package Library;

#-------------------------------------------------------------------------------
class Configuration {

  has Str $!cfg-filename;
  has Hash $.config;

  #-----------------------------------------------------------------------------
  # We only have to load it once, after that saving is the only step needed
  submethod BUILD ( ) {

    $!cfg-filename = $*HOME ~ '/.library.toml';
    $!config = from-toml(:file($!cfg-filename));
  }

  #-----------------------------------------------------------------------------
  method save ( Bool :$use-home-dir = True ) {

    spurt( $!cfg-filename, to-toml($!config));
  }
}


