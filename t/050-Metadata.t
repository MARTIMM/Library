use v6;
use Test;

use Library;
use Library::Metadata::Database;
use BSON::Document;

#-------------------------------------------------------------------------------
subtest 'Metadata', {

  # setup another config
  mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
  %*ENV<LIBRARY-CONFIG> = 't/Lib4';
  my Str $filename = 't/Lib4/config.toml';
  spurt( $filename, Q:to/EOCFG/);

    # MongoDB server connection
    uri         = 'mongodb://localhost:27017'

    database    = 'test'

    [ collection ]
      meta-data = 'mdb'

    EOCFG

  initialize-library();

  my Library::Metadata::Database $mdb .= new;
  $mdb.update-meta( :object<t/030-OT-File.t>, :type(OT-File));
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);
