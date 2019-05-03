use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB;
use MongoDB::Client;
use MongoDB::Server;

use Library::Configuration;

#-------------------------------------------------------------------------------
# Values are Str so they can be used as type value in a mongodb document
enum MetaType is export <<
  :MT-File('File') :MT-Directory('Directory')
  :MT-Program('Program') :MT-User('User') :MT-Web('Web')
>>;

our $lib-cfg;           # Type Library::Configuration
our $client;            # Type MongoDB::Client
our $refine-key;        # Type Str
 # $?MODULE.^ver;   # '0.13.0';#$?PACKAGE.^ver;


#-------------------------------------------------------------------------------
sub initialize-library ( Str :$refine-key = 'default' ) is export {

  $Library::refine-key = $refine-key;

  # check for config directory
  my Str $config-dir = check-config-dir();

  # set config file if it does not exist
  my Str $cfg-file = "$config-dir/client-configuration.toml";
  unless $cfg-file.IO ~~ :r {
    spurt( $cfg-file, Q:qq:to/EOCFG/);
      #TODO root-db and contents of tables [ library.collections.root ]
      # should be fixed? Settable in Configuration object

      [ connection ]

        # one of three possible ways to describe a servername
        server              = "localhost.localdomain"
        #server                 = "127.0.0.1"
        #server                 = "::1"

        port                = 27017

      #[ connection.user.marcel ]
      #  password            = "some-pw"
      #  database            = "MyLibrary"
      #TODO thoughts
      #  logfile             = "Mylibrary.log

      #[ connection.options ]
      #  replicaSet          = MetaLibrary
      #  connectTimeoutMS    = 30000
      #...

      [ library ]
        # in other config:
        #recursive-scan-dirs = [  ]

        # user-db can be used when no users are specified. root-db is used
        # for collections which must be available to all users.
        user-db             = "MyLibrary"

        logfile             = "library.log"
        loglevelfile        = "Warn"
        loglevelscreen      = "Warn"

      [ library.collections ]
        meta-data           = "Metadata"
        meta-config         = "Metaconfig"

      #TODO thoughts
      [ library.mimetypes ]
        image/jpeg          = "/usr/bin/gwenview %u"
        image/*             = "/usr/bin/gwenview %u"

      [ library.programs ]

      EOCFG

#    warn-message(
#      "A default config file is written at $config-dir" ~
#      "/client-configuration.toml, adjust if needed, exiting..."
#    );
#    exit(1);
  }

  # clean configuration and set to new
  $lib-cfg = Library::Configuration.new(
    :library-config("$config-dir/client-configuration.toml"),
    :$refine-key
  );

#`{{
  # setup logging
  my Str $log-file;
  my MongoDB::MdbLoglevels $log-levelfile;
  my MongoDB::MdbLoglevels $log-levelscreen;
  ( $log-file, $log-levelfile, $log-levelscreen) = $lib-cfg.get-loginfo;
note "Loglevel types screen, file: ", $log-levelscreen, ', ', $log-levelfile;
note "Log file: ", $log-file;

  drop-send-to('screen');
  drop-send-to('mongodb');
  add-send-to( 'libs', :to($*ERR), :min-level($log-levelscreen));
  my $handle = "$config-dir/$log-file".IO.open( :mode<wo>, :create, :append);
  add-send-to( 'libf', :to($handle), :min-level($log-levelfile));
  info-message("Log file opened");
}}
}

#-------------------------------------------------------------------------------
sub connect-meta-data-server ( ) is export {

  # throw old client object and get a new one.
  $client.cleanup if $client.defined;

  # note that uri is not defined in the configfile. it will be set when the
  # config is checked by Library::Configuration.
  $client = MongoDB::Client.new(:uri($lib-cfg.lib-config<uri>));
#  info-message("Config initialized");
note "Config initialized, ", $client;
}

#-------------------------------------------------------------------------------
sub db-topology ( --> TopologyType ) is export {
  $client.topology
}

#-------------------------------------------------------------------------------
sub db-server ( --> Str ) is export {
  my MongoDB::Server $server = $client.select-server;
  $server.name
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
