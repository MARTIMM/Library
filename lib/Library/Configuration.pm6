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
  has Str $!user-key;

  #-----------------------------------------------------------------------------
  # We only have to load it once
  submethod BUILD (
    Str:D :library-config($file), Bool :$generate = False, Str :$!user-key
  ) {

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

#note "\nConfig:\n", $!config.perl;
    # set defaults if needed
    self!check-config-field( <connection server>, :default<localhost>);
    self!check-config-field( <connection port>, :default(27017));
    self!check-config-field( <library recursive-scan-dirs>, :default([]));

    self!check-config-field( <library database>, :default<Library>);
    self!check-config-field(
      <library collections meta-data>, :default<Metadata>
    );
    self!check-config-field(
      <library collections meta-config>, :default<Metaconfig>
    );

#note "\nConfig:\n", $!config.perl;


    # create uri from config data
    $!config<connection><uri> = 'mongodb://';

    # add user spec to rti
    if $!user-key {
#TODO modify
#[ connection.authentication.u1 ]
#user                = "marcel"
#password            = "Dans3r3s"

      if ? (my $user-hash = $!config<connection><user>{$!user-key}) {
        $!config<connection><uri> ~= $user-hash<user>;
        $!config<connection><uri> ~= ":$user-hash<password>"
          if ? $user-hash<password>;

        $!config<connection><uri> ~= '@';
      }
    }

    # add hostname. can be name.domain, ip4 or ip6 address.
    # server field must be checked for ip6 address. must be enclosed in [].
    my Str $server = $!config<connection><server>;
    $server = "[$server]" if $server ~~ /\:/;
    $!config<connection><uri> ~=
      $server ~ ':' ~ $!config<connection><port> ~ '/' ~
      $!config<library><database>;

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

    # descent using field names into the configuration
    for @fields -> $field {

      # when field is missing or empty set the Bool and init with empty Hash
      unless ? $c{$field} {
        $missing-key = True;
        $c{$field} = {};
      }

      # keep current config to set the default when we are ready
      $p := $c;

      # descent forther down if possible
      $c := $c{$field} if $c{$field} ~~ Hash;
    }

    # if any of the keys were missing, set the field to its default
    # which overwrites the previously set empty Hash
    if $missing-key {
      $p{@fields[*-1]} = $default;
      warn-message(
        "Missing keys '{@fields.join('.')}' from config, set to '$default'"
      );
    }
  }
}
