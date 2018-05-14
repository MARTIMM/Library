use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB;
use MongoDB::Client;
use Library::Configuration;

#-------------------------------------------------------------------------------
# Values are Str so they can be used as type value in a mongodb document
enum ObjectType is export <<
  :OT-File('File') :OT-Directory('Directory')
  :OT-Program('Program') :OT-User('User') :OT-Web('Web')
>>;

our $lib-cfg is export;
our $client is export;

#-------------------------------------------------------------------------------
sub initialize-library ( ) is export {

  # check for config directory
  my Str $config-dir = check-config-dir();

  # setup logging
  modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
  modify-send-to(
    'mongodb',
    :pipe("sort > $config-dir/store-file-metadata.log")
  );

  # set config file if it does not exist
  my Str $cfg-file = "$config-dir/client-configuration.toml";
  unless $cfg-file.IO ~~ :r {
    spurt( $cfg-file, Q:qq:to/EOCFG/);
      [ connection ]

      # one of three possible ways to describe a servername
      server              = "localhost.localdomain"
      #server                 = 127.0.0.1
      #server                 = ::1

      port                = 27017
      #user                = "marcel"
      #password            = "Dans3r3s"

      [ connection.options ]
      replicaSet          = MetaLibrary


      [ library ]
      recursive-scan-dirs = [  ]

      [ library.database ]
      library             = "Library"

      [ library.collection ]
      meta-config         = "Metaconfig"
      meta-data           = "Metadata"

      EOCFG

    warn-message(
      "A default config file is written at $config-dir" ~
      "/client-configuration.toml, adjust if needed, exiting..."
    );
    exit(1);
  }

  # clean configuration and set to new
  $lib-cfg = Nil if $lib-cfg.defined;
  $lib-cfg = Library::Configuration.new(
    :library-config("$config-dir/client-configuration.toml")
  );

  # throw old client object and get a new one.
  $client.cleanup if $client.defined;

  # note that uri is not defined in the configfile. it will be set when the
  # config is checked by Library::Configuration.
  $client = MongoDB::Client.new(:uri($lib-cfg.config<connection><uri>));
}

#-------------------------------------------------------------------------------
# setup config directory
sub check-config-dir ( --> Str ) {

  my Str $config-dir;

  # get config directory path
  if %*ENV<LIBRARY_CONFIG>:exists {
    $config-dir = %*ENV<LIBRARY_CONFIG>;
  }

  else {
    $config-dir = "$*HOME/.library";
    %*ENV<LIBRARY_CONFIG> = $config-dir;
  }


  # check if directory exists
  if $config-dir.IO !~~ :e {
    mkdir $config-dir, 0o700;
    info-message("Config directory created");
  }

  elsif %*ENV<LIBRARY_CONFIG>.IO ~~ :d {
    debug-message("Config directory found");
  }

  # else check if existent but other than directory
  elsif $config-dir.IO ~~ :e {
    fatal-message("Name $config-dir exists but isn't a directory");
  }

  $config-dir
}
