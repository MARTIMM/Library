use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Metadata::Database;
use BSON::Document;

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');

# setup config directory
mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
%*ENV<LIBRARY-CONFIG> = 't/Lib4';
my Str $filename = 't/Lib4/config.toml';
spurt( $filename, Q:qq:to/EOCFG/);

  # MongoDB server connection
  uri         = "mongodb://localhost:$p1"

  database    = 'test'

  [ collection ]
    meta-data = 'meta050'

  EOCFG

initialize-library();

#-------------------------------------------------------------------------------
subtest 'Metadata', {

  my Library::Metadata::Database $mdb .= new;
  $mdb.update-meta( :object<t/030-OT-File.t>, :type(OT-File));
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/config.toml';
rmdir 't/Lib4';

exit(0);
