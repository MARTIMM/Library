use v6;
use Test;

use Library::Configuration;

#-------------------------------------------------------------------------------
subtest 'automatic configuration', {

  my Library::Configuration $cfg .= new(:library-config<t/Lib1>);
  isa-ok $cfg, 'Library::Configuration';

  is $cfg.config<uri>, 'mongodb://', 'uri from automatic config';
}

#-------------------------------------------------------------------------------
subtest 'configuration load and save', {

  mkdir 't/Lib2', 0o700;
  my Str $filename = 't/Lib2/config.toml';
  spurt( $filename, Q:to/EOCFG/);

    # MongoDB server connection
    uri             = 'mongodb://localhost:27017'

    EOCFG

  my Library::Configuration $cfg .= new(:library-config<t/Lib2>);
  is $cfg.config<uri>, 'mongodb://localhost:27017', 'uri from config';
  $cfg.config<my-data> = 'test 1';
  $cfg.save;
}

#-------------------------------------------------------------------------------
subtest 'configuration load', {

  %*ENV<LIBRARY-CONFIG> = 't/Lib2';
  my Library::Configuration $cfg .= new;
  is $cfg.config<my-data>, 'test 1', 'found setting "test 1"';
#  $cfg.config<my-data>:delete;
#  $cfg.save;
}

#-------------------------------------------------------------------------------
#cleanup
done-testing;

unlink 't/Lib1/config.toml';
rmdir 't/Lib1';

unlink 't/Lib2/config.toml';
rmdir 't/Lib2';

exit(0);

