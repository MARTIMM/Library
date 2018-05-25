use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Storage;
use Library::Metadata::Object::Directory;
use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
#drop-send-to('mongodb');
#drop-send-to('screen');
modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
info-message("Test $?FILE start");

#------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');

# setup config directory
mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
%*ENV<LIBRARY_CONFIG> = 't/Lib4';
my Str $filename = 't/Lib4/client-configuration.toml';
spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      # MongoDB server connection
      server      = "localhost"
      port        = "$p1"

    [ library ]
      user-db     = 'test'
      root-db     = 'meta031'

    [ library.collections ]
      meta-data   = "meta031-data"

    [ library.collections.root ]
      meta-config = "meta031-cfg"

    EOCFG

initialize-library;

#------------------------------------------------------------------------------
subtest 'OT File', {

  my Library::Storage $dbo .= new(:collection-key<meta-data>);
  my Library::Metadata::Object::Directory $dir;

  $dir .= new( :$dbo, :object<t/Lib4>, :type(OT-Directory));
  my BSON::Document $d = $dir.meta;
  diag $d.perl;
  is $d<name>, 'Lib4', $d<name>;
  like $d<path>, /:s t $/, $d<path>;
  ok $d<exists>, 'object exists';


  $dir .= new( :$dbo, :object<t/Lib4/no-dir>, :type(OT-Directory));
  $d = $dir.meta;
  diag $d.perl;
  is $d<name>, 'no-dir', $d<name>;
  like $d<path>, /:s t\/Lib4 $/, $d<path>;
  ok !$d<exists>, 'object does not exist';
}

#------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/client-configuration.toml';
rmdir 't/Lib4';

exit(0);
