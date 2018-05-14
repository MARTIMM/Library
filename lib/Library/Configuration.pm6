use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Config::TOML;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;

#-------------------------------------------------------------------------------
class Configuration {

  has Hash $.config;

  #-----------------------------------------------------------------------------
  # We only have to load it once
  submethod BUILD ( Str:D :library-config($file), Bool :$generate = False ) {



    if $generate {
      $!config = $file.IO ~~ :r ?? from-toml(:$file) !! {};
    }

    else {
      $!config = from-toml(:$file);
    }

    self!check-config;
  }

  #-----------------------------------------------------------------------------
  method !check-config ( ) {

    # set defaults if needed
    self!check-config-field( <connection server>, :default<localhost>);
    self!check-config-field( <connection port>, :default(27017));
    self!check-config-field( <library recursive-scan-dirs>, :default([]));
    self!check-config-field( <library database library>, :default<Library>);
    self!check-config-field(
      <library collection meta-data>, :default<Metadata>
    );
    self!check-config-field(
      <library collection meta-config>, :default<Metaconfig>
    );

note "\nConfig:\n", $!config.perl;

    # create uri from config data
    $!config<connection><uri> = 'mongodb://';
    if ? $!config<connection><user> {
      $!config<connection><uri> ~= $!config<connection><user>;
      $!config<connection><uri> ~= ":$!config<connection><password>"
        if ? $!config<connection><password>;

      $!config<connection><uri> ~= '@';
    }

    # server check for ip6 address. must be enclose in []
    my Str $server = $!config<connection><server>;
    $server = "[$server]" if $server ~~ /\:/;
    $!config<connection><uri> ~=
      $server ~ ':' ~ $!config<connection><port> ~ '/' ~
      $!config<library><database><library>;

    # add options
    if $!config<connection><options>:exists {
      my @optlist = ();
      $!config<connection><uri> ~= '?';
      for $!config<connection><options>.keys -> $option {
        @optlist.push:
          "$option=$!config<connection><options>{$option}";
      }
      $!config<connection><uri> ~= @optlist.join('&');
    }

    info-message("Connect with '$!config<connection><uri>'");
  }

  #-----------------------------------------------------------------------------
  method !check-config-field ( *@fields, Str :$default ) {

    my Bool $missing-key = False;
    my Hash $c := $!config;
    my Hash $p;

    for @fields -> $field {
      unless ? $c{$field} {
        $missing-key = True;
        $c{$field} = {};
      }

      $p := $c;
      $c := $c{$field};
    }

    if $missing-key {
      $p{@fields[*-1]} = $default;
      warn-message(
        "Missing keys '{@fields.join('.')}' from config, set to '$default'"
      );
    }
  }
}
