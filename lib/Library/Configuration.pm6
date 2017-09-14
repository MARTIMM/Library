use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library::X;

use Config::TOML;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;

#------------------------------------------------------------------------------
class Configuration {

  has Str $!config-filename;
  has Hash $.config;

  #----------------------------------------------------------------------------
  # We only have to load it once, after that, saving is the only step needed
  # after every update
  submethod BUILD ( ) {

    my Str $config-dir = %*ENV<LIBRARY-CONFIG> // "$*HOME/.library";

    # check if directory exists
    if $config-dir.IO ~~ :d {
      my Str $file = $config-dir ~ '/config.toml';
      $!config-filename = $file;
      $!config = $config-dir.IO ~~ :r ?? from-toml(:$file) !! {};
    }

    # else check if existent
    elsif $config-dir.IO ~~ :e {
      die X::Library.new(:message("Name $config-dir exists but isn't a directory"));
    }

    # create directory
    else {
      mkdir $config-dir, 0o750;
      $!config-filename = $config-dir ~ '/config.toml';
      $!config = {};
    }

    self!check-config;
  }

  #----------------------------------------------------------------------------
  method save ( ) {

    spurt( $!config-filename, to-toml($!config));
  }

  #----------------------------------------------------------------------------
  method !check-config ( ) {

    $!config<uri> //= 'mongodb://';
    $!config<database> = "Library";
    $!config<recursive-scan-dirs> = [];
    $!config<collection><meta-data> = "Metadata";
    $!config<collection><meta-config> = "Metaconfig";

    self.save;
  }
}
