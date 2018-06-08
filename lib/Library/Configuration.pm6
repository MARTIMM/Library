use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Config::TOML;
use MongoDB;

#-------------------------------------------------------------------------------
class Configuration {

  has Hash $.config;
  has Str $!user-key;

  #-----------------------------------------------------------------------------
  # We only have to load it once
  submethod BUILD (
    Str:D :library-config($file), Bool :$generate = False, Str :$!user-key
  ) {

    # when generate is true, we start with an empty hash if no file is found
    if $generate {
      $!config = $file.IO ~~ :r ?? from-toml(:$file) !! {};
    }

    else {
      $!config = from-toml(:$file);
    }

    self!check-config;

    # write to file if generate is true and file didn't exist
    spurt( $file, to-toml($!config)) if $generate and !$file.IO.e;
  }

  #-----------------------------------------------------------------------------
  method database-name ( Bool :$root = False --> Str ) {

    my Str $db-name;

    if $root {
      $db-name = $!config<library><root-db>;
    }

    else {
      if $!user-key {
        $db-name = $!config<connection><user>{$!user-key}<database>;
      }

      else {
        #$db-name = $!config<library><database>;
        $db-name = $!config<library><user-db>;
      }
    }

    $db-name;
  }

  #-----------------------------------------------------------------------------
  method collection-name (
    Str:D $collection-key, Bool :$root = False
    --> Str
  ) {

    my Str $cl-name;

    if $root {
      $cl-name = $!config<library><collections><root>{$collection-key};
    }

    else {
      $cl-name = $!config<library><collections>{$collection-key};
    }

    $cl-name;
  }

  #-----------------------------------------------------------------------------
  method get-loginfo ( --> List ) {
    ( $!config<library><logfile>,
      $!config<library><loglevelfile>,
      $!config<library><loglevelscreen>
    )
  }

  # ==[ Private Stuff ]=========================================================
  #-----------------------------------------------------------------------------
  method !check-config ( ) {

#note "\nConfig:\n", $!config.perl;
    # set defaults if needed
    self!check-config-field( <connection server>, :default<localhost>);
    self!check-config-field( <connection port>, :default(27017));
#    self!check-config-field( <library recursive-scan-dirs>, :default([]));

    self!check-config-field( <library root-db>, :default<Library>);
    self!check-config-field( <library user-db>, :default<MyLibrary>);
    self!check-config-field( <library logfile>, :default<library.log>);

    self!check-config-field( <library loglevelfile>, :default<Warn>);
    self!check-config-field( <library loglevelscreen>, :default<Warn>);
    self!check-loglevel($!config<library><loglevelfile>);
    self!check-loglevel($!config<library><loglevelscreen>);

    self!check-config-field(
      <library collections meta-data>, :default<Metadata>
    );
    self!check-config-field(
      <library collections meta-config>, :default<Metaconfig>
    );
    self!check-config-field(
      <library collections root mimetypes>, :default<Mimetypes>
    );

#note "\nConfig:\n", $!config.perl;

    # create uri from config data
    $!config<connection><uri> = 'mongodb://';

    # add user spec to rti
    if $!user-key {
      if ? (my $user-hash = $!config<connection><user>{$!user-key}) {
        $!config<connection><uri> ~= $user-hash<user>;
        $!config<connection><uri> ~= ":$user-hash<password>";
        $!config<connection><uri> ~= '@';
      }
    }

    # add hostname. can be name.domain, ip4 or ip6 address.
    # server field must be checked for ip6 address. must be enclosed in [].
    my Str $server = $!config<connection><server>;
    $server = "[$server]" if $server ~~ /\:/;
    $!config<connection><uri> ~=
      $server ~ ':' ~ $!config<connection><port> ~ '/' ~
      self.database-name;

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
      debug-message(
        "Missing keys '{@fields.join('.')}' from config, set to '$default'"
      );
    }
  }

  #-----------------------------------------------------------------------------
  method !check-loglevel ( $log-level is rw ) {

    given $log-level {
      when 'Trace' {
        $log-level = MongoDB::MdbLoglevels::Trace;
      }

      when 'Debug' {
        $log-level = MongoDB::MdbLoglevels::Debug;
      }

      when 'Info' {
        $log-level = MongoDB::MdbLoglevels::Info;
      }

      when 'Warn' {
        $log-level = MongoDB::MdbLoglevels::Warn;
      }

      when 'Error' {
        $log-level = MongoDB::MdbLoglevels::Error;
      }

      when 'Fatal' {
        $log-level = MongoDB::MdbLoglevels::Fatal;
      }

      default {
        $log-level = MongoDB::MdbLoglevels::Warn;
      }
    }
  }
}
