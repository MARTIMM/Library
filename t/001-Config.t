use v6;
use Test;

use Library::Configuration;

spurt( $*HOME ~ '/.library.toml', Q:to/EOCFG/);

  # MongoDB server connection
  uri             = 'mongodb://localhost:27017'

  EOCFG

#-------------------------------------------------------------------------------
subtest 'configuration save', {
  my Library::Configuration $cfg .= new;
  isa-ok $cfg, 'Library::Configuration';

  is $cfg.config<uri>, 'mongodb://localhost:27017', 'uri from config';
  
  $cfg.config<my-data> = 'test 1';
  $cfg.save;
}

#-------------------------------------------------------------------------------
subtest 'configuration load', {
  my Library::Configuration $cfg .= new;

  is $cfg.config<my-data>, 'test 1', 'found setting';
  $cfg.config<my-data>:delete;
  $cfg.save;
}

#-------------------------------------------------------------------------------


done-testing;

#unlink $filename;

exit(0);

