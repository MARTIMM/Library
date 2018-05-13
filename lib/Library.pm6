use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB;
use MongoDB::Client;
use Library::Configuration;

#------------------------------------------------------------------------------
# Values are Str so they can be used as type value in a mongodb document
enum ObjectType is export <<
  :OT-File('File') :OT-Directory('Directory')
  :OT-Program('Program') :OT-User('User') :OT-Web('Web')
>>;

our $lib-cfg is export;
our $client is export;

#------------------------------------------------------------------------------
sub initialize-library ( ) is export {

  # check for config directory
  my Str $cfg-dir = check-config-dir();

  # setup logging
  modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
  modify-send-to( 'mongodb', :pipe("sort > $cfg-dir/store-file-metadata.log"));

  # set config file if it does not exist
  my Str $cfg-file = "$cfg-dir/client-configuration.toml";
  unless $cfg-file.IO ~~ :r {
    spurt( $cfg-file, Q:qq:to/EOCFG/);
      [ connection ]

      # one of three possible ways to describe a servername
      hostname            = "localhost.localdomain"
      ip4                 = 127.0.0.1
      ip6                 = ::1

      port                = 27017
      replSet             = MetaLibrary

      #user                = "marcel"
      #? password            = "Dans3r3s"

      [ library ]
      recursive-scan-dirs = [  ]

      [ library.database ]
      library             = "Library"

      [ library.collection ]
      meta-config         = "Metaconfig"
      meta-data           = "Metadata"

      EOCFG

    warn-message(
      "A default config file is written at $cfg-dir/client-configuration.toml" ~
      ", adjust if needed, exiting..."
    );
    exit(1);
  }

  # clean data and set to new
  $lib-cfg = Nil if $lib-cfg.defined;
  $lib-cfg = Library::Configuration.new;

  $client.cleanup if $client.defined;
  $client = MongoDB::Client.new(:uri($lib-cfg.config<uri>));
}

#------------------------------------------------------------------------------
# setup config directory
sub check-config-dir ( --> Str ) {

  my $cfg-dir;
  if %*ENV<LIBRARY_CONFIG>:exists and %*ENV<LIBRARY_CONFIG>.IO ~~ :d {
    $cfg-dir = %*ENV<LIBRARY_CONFIG>;
  }

  else {
    $cfg-dir = "$*HOME/.library";
    %*ENV<LIBRARY_CONFIG> = $cfg-dir;
  }

  mkdir $cfg-dir, 0o700 unless $cfg-dir.IO ~~ :d;
}
