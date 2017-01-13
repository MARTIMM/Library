use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Config::TOML;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;

#-------------------------------------------------------------------------------
class Configuration {

  has Str $!config-filename;
  has Hash $.config;

  #-----------------------------------------------------------------------------
  # We only have to load it once, after that, saving is the only step needed
  # after every update
  #
  submethod BUILD ( Str :$library-config ) {

    my Str $file = $library-config
                 // %*ENV<LIBRARY-CONFIG>
                 // "$*HOME/.library";

    if $file.IO ~~ :d {
      $file ~= '/config.toml';
      $!config = $file.IO ~~ :r ?? from-toml(:$file) !! {};
    }

    else {
      mkdir $file, 0o750;
      $file ~= '/config.toml';
      $!config = {};
    }

    $!config-filename = $file;
    self!check-config;
  }

  #-----------------------------------------------------------------------------
  method save ( ) {

    spurt( $!config-filename, to-toml($!config));
  }

  #-----------------------------------------------------------------------------
  method !check-config ( ) {

    $!config<uri> = 'mongodb://' unless ? $!config<uri>;
    self.save;
  }
}


