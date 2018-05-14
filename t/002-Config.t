use v6;
use Test;

use Library;
use Library::Configuration;

#-------------------------------------------------------------------------------
subtest 'automatic configuration', {

  throws-like( {
      my Library::Configuration $cfg .= new(:library-config<t/Lib1>);
    }, Exception, 'Missing config file',
    :message(/:s Failed to open file/)
  );


  my Library::Configuration $cfg .= new(
    :library-config<t/Lib1/config.toml>, :generate
  );
  isa-ok $cfg, 'Library::Configuration';
  is $cfg.config<connection><uri>, 'mongodb://localhost:27017/Library', 'uri from automatic config';
}

#-------------------------------------------------------------------------------
subtest 'configuration load and save', {

  mkdir 't/Lib2', 0o700 unless 't/Lib2'.IO ~~ :d;
  my Str $filename = 't/Lib2/config.toml';
  spurt( $filename, Q:to/EOCFG/);

    #[ connection ]
      # MongoDB server connection
      #uri             = 'mongodb://marcel@[::1]:27000/Library'
      server  = '::1'
      port    = 27000
      user    = 'marcel'

    EOCFG

  my Library::Configuration $cfg .= new(:library-config($filename));
  is $cfg.config<connection><uri>, 'mongodb://marcel@[::1]:27000/Library',
     'uri from config';
  $cfg.config<my-data> = 'test 1';
}

#`{{
#-------------------------------------------------------------------------------
subtest 'configuration load', {

  %*ENV<LIBRARY_CONFIG> = 't/Lib2';
  my Library::Configuration $cfg .= new;
  is $cfg.config<my-data>, 'test 1', 'found setting "test 1"';
}
}}

#-------------------------------------------------------------------------------
subtest 'library module init', {

  %*ENV<LIBRARY_CONFIG> = 't/Lib3';
  initialize-library();

  is $Library::lib-cfg.config<connection><uri>,
     'mongodb://localhost:27017/Library', 'found lib uri';
  isa-ok $Library::client, 'MongoDB::Client';
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib1/config.toml';
rmdir 't/Lib1';

unlink 't/Lib2/config.toml';
rmdir 't/Lib2';

unlink 't/Lib3/config.toml';
rmdir 't/Lib3';

exit(0);
