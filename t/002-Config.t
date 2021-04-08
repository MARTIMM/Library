use v6;
use Test;

use Library;
use Library::Configuration;

#-------------------------------------------------------------------------------
my Str $dir = 't/Lib1';
mkdir $dir, 0o700 unless $dir.IO ~~ :d;

my Str $file = "$dir/config.toml";

my Library::Configuration $cfg;

#-------------------------------------------------------------------------------
subtest 'automatic configuration', {
  throws-like( {
      $cfg .= new(:library-config($file));
    }, Exception, 'Non existent config file',
    :message(/:s not found or empty/)
  );
}

#-------------------------------------------------------------------------------
subtest 'configuration load and save', {

  spurt( $file, Q:to/EOCFG/);
    # possible keys
    'section-keys' = [ 'superuser', 'projects', 'extern', 'projects2']

    # defaults
    [connection]
    port = 65140
    server = "192.168.0.253"

    [connect-options]
    replicaSet = "MetaLibrary"

    [program]
    logfile = "library.log"
    loglevelfile = 'Warn'
    loglevelscreen = 'Warn'

    [database]
    db-name = "MetaLibrary"
    meta-config = "MetaConfig"
    meta-data = "MetaData"

    # TODO:0 thoughts
    [mimetypes]
    'image/jpeg'          = "/usr/bin/gwenview %u"
    'image/*'             = "/usr/bin/gwenview %u"

    # super user
    [database.superuser]
    username = 'admin'
    password = 'MTc3LjouMTQ2LjouMjA5LjouMjEwLjouMjE4LjouMjA5LjouMTUy'
    db-name = "admin"

    # projects of user marcel
    [program.projects]
    logfile = "projects.log"
    loglevelfile = 'Info'
    loglevelscreen = 'Debug'

    [database.projects2]
    db-name = "mt1957"
    meta-config = "MetaConfig"
    meta-data = "MetaData"

    [database.projects]
    username = 'marcel'
    password = 'MTcyLjouMTQ2LjouMjIxLjouMjE3LjouMjEwLjouMTUx'
    db-name = "mt1957"
    meta-config = "MetaConfig"
    meta-data = "MetaData"

    # extern user test
    [database.extern]
    username = 'test'
    password = 'MTk1LjouMTQ3LjouMjE1LjouMjA0LjouMjE4LjouMjEyLjouMjE5LjouMTU1LjouMjE5'
    db-name = "test"
    meta-config = "Docs-Config"
    meta-data = "Docs-Data"

    EOCFG

  $cfg .= new( :library-config($file), :refine-key<u1>);
note "C: ", $cfg.config;

  is $cfg.config<connection><uri>,
     'mongodb://marcel:tplus@[::1]:27000/mt-data',
     'uri: ' ~ $cfg.config<connection><uri>;
#  $cfg.config<my-data> = 'test 1';

  $cfg .= new( :library-config($file), :refine-key<u2>);
  is $cfg.config<connection><uri>, 'mongodb://piet:puk@[::1]:27000/my-data',
     'uri: ' ~ $cfg.config<connection><uri>;
}

#`{{
#-------------------------------------------------------------------------------
subtest 'configuration load', {

  %*ENV<LIBRARY_CONFIG> = 't/Lib1';
  my Library::Configuration $cfg .= new;
  is $cfg.config<my-data>, 'test 1', 'found setting "test 1"';
}
}}

#-------------------------------------------------------------------------------
subtest 'library module init', {

  # config file is fixed by library init
  %*ENV<LIBRARY_CONFIG> = $dir;
  my Str $filename = "$dir/client-configuration.toml";
  spurt( $filename, '[ configuration ]');
  initialize-library();

  is $Library::lib-cfg.config<connection><uri>,
     'mongodb://localhost:27017/MyLibrary', 'found default lib uri';
  isa-ok $Library::client, 'MongoDB::Client';
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink 't/Lib1/config.toml';
#unlink 't/Lib1/client-configuration.toml';
#unlink 't/Lib1/store-file-metadata.log';
#rmdir 't/Lib1';

exit(0);
