use v6;
use Test;

use Library;
use Library::Configuration;

#-------------------------------------------------------------------------------
my Str $dir = 't/Lib1';
mkdir $dir, 0o700 unless $dir.IO ~~ :d;

my Str $file = "$dir/config.toml";

#-------------------------------------------------------------------------------
subtest 'automatic configuration', {

  throws-like( {
      my Library::Configuration $cfg .= new(:library-config($file));
    }, Exception, 'Non existent config file',
    :message(/:s Failed to open/)
  );

  my Library::Configuration $cfg .= new( :library-config($file), :generate);
  isa-ok $cfg, 'Library::Configuration';
  is $cfg.config<connection><uri>,
    'mongodb://localhost:27017/MyLibrary',
    'uri from automatic config';
}

#-------------------------------------------------------------------------------
subtest 'configuration load and save', {

  spurt( $file, Q:to/EOCFG/);

    [ connection ]
      server    = "::1"
      port      = 27000

    [ connection.user.u1 ]
      user      = "marcel"
      password  = "tplus"
      database  = "mt-data"

    [ connection.user.u2 ]
      user      = "piet"
      password  = "puk"
      database  = "my-data"

    [ library ]
      root-db   = "Library"
      user-db   = "MyLibrary"

    EOCFG

  my Library::Configuration $cfg .= new( :library-config($file), :user-key<u1>);
  is $cfg.config<connection><uri>,
     'mongodb://marcel:tplus@[::1]:27000/mt-data',
     'uri: ' ~ $cfg.config<connection><uri>;
#  $cfg.config<my-data> = 'test 1';

  $cfg .= new( :library-config($file), :user-key<u2>);
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

unlink 't/Lib1/config.toml';
unlink 't/Lib1/client-configuration.toml';
unlink 't/Lib1/store-file-metadata.log';
rmdir 't/Lib1';

exit(0);
