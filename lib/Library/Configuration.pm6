use v6;

=begin pod

=head1 Library::Configuration

=head2 Class defining the location where program info can be stored.

=end pod

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Config::TOML;
use Config::DataLang::Refine;
use MongoDB;
use MIME::Base64;

#-------------------------------------------------------------------------------
class Configuration {

  has Config::DataLang::Refine $!rc;
  has Hash $.prog-config;
  has Hash $.config;
  has Hash $.lib-config;
  has Str $!refine-key;
  has Str $!library-config;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    Str:D :$!library-config, :$!refine-key = 'default'
  ) {

#note "LC: $!library-config";
    $!rc .= new(:config-name($!library-config));
    $!config := $!rc.config;
    self.reconfig;
  }

  #-----------------------------------------------------------------------------
  method database-name ( Bool :$use-lib-db = False --> Str ) {

    if $use-lib-db {
      $!lib-config<db-name>
    }

    else {
      $!prog-config<database><db-name>
    }
  }

  #-----------------------------------------------------------------------------
  method collection-name (
    Str:D $collection-key, Bool :$use-lib-db = False
    --> Str
  ) {

    if $use-lib-db {
      $collection-key
    }

    else {
      die unless $collection-key ~~ any(<meta-config meta-data>);
      $!prog-config<database>{$collection-key}
    }
  }

  #-----------------------------------------------------------------------------
  method get-loginfo ( --> List ) {
    ( $!prog-config<program><logfile>,
      $!prog-config<program><loglevelfile>,
      $!prog-config<program><loglevelscreen>
    )
  }

  #-----------------------------------------------------------------------------
  method save-config ( ) {

    $!library-config.IO.spurt(to-toml($!config));
    $!rc .= new(:config-name($!library-config));
  }

  #-----------------------------------------------------------------------------
  method reconfig ( Str :$!refine-key = 'Default' ) {

    # check for changed data
    $!lib-config = {};
    self!refine-config;
    self!check-config;

#note "$!library-config, $!refine-key";
#note "\nCfg: ", $!config;
#note "\nProg Cfg: ", $!prog-config;
#note "\nLib-cfg: ", $!lib-config;
  }

  # ==[ Private Stuff ]=========================================================
  method !refine-config ( ) {

    $!prog-config = %(
      connection => ($!rc.refine( 'connection', $!refine-key)),
      connect-options => ($!rc.refine( 'connect-options', $!refine-key)),
      program => ($!rc.refine( 'program', $!refine-key)),
      database => ($!rc.refine( 'database', $!refine-key)),
      mimetypes => ($!rc.refine( 'mimetypes', $!refine-key)),
#      => ($!rc.refine( '', $!refine-key)),
    );
  }

  #-----------------------------------------------------------------------------
  method !check-config ( ) {

    # fixed data is in $!lib-config
    $!lib-config<db-name> = "Library";
    $!lib-config<extensions> = "Extensions";
    $!lib-config<mimetypes> = "Mimetypes";
    $!lib-config<refined> = $!refine-key;

    # create uri from config data
    $!lib-config<uri> = 'mongodb://';

    # add user spec to uri
    if $!refine-key ne 'default' {
      my Str $un = $!config<database>{$!refine-key}<username> // '';
      my Str $ecpw = $!config<database>{$!refine-key}<password> // '';
      if 0 { #TODO authentication ... ?$un and ?$ecpw {
        my Str $pw = utf8.new(
          utf8.new(
            MIME::Base64.decode-str($ecpw).split('.:.')>>.Int
          ) Z- 'abcdefghijklmnopqrstuvwxyz'.encode
        ).decode;

        $!lib-config<uri> ~= "$un:$pw\@";
      }
    }

    # add hostname. can be name.domain, ip4 or ip6 address.
    # server field must be checked for ip6 address. must be enclosed in [].
    my Str $server = $!config<connection><server>;
    $server = "[$server]" if $server ~~ /\:/;
    $!lib-config<uri> ~= $server ~ ':' ~ $!config<connection><port> ~
                          '/' ~ self.database-name;

    # add options
    if $!config<connect-options>:exists {
      my @optlist = ();
      for $!config<connect-options>.keys -> $option {
        @optlist.push: "$option=$!config<connect-options>{$option}";
      }
      $!lib-config<uri> ~= '?';
      $!lib-config<uri> ~= @optlist.join('&');
    }

#todo check-loglevel
    #info-message("Connect with '$!lib-config<uri>'");
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
