use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Metadata::Database;
use Library::Metadata::Object::Directory;
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
    meta-data = 'meta031'

  EOCFG

initialize-library();

#-------------------------------------------------------------------------------
subtest 'OT File', {

  my Library::Metadata::Database $dbo .= new;
  my Library::Metadata::Object::Directory $dir;
  
  $dir .= new( :$dbo, :object<lib/Library>, :type(OT-Directory));
  my BSON::Document $d = $dir.meta;
  is $d<name>, 'Library', $d<name>;
  like $d<path>, /:s lib $/, $d<path>;
  ok $d<exists>, 'object exists';

  say $d.perl;

  $dir .= new( :$dbo, :object<lib/Library/no-dir>, :type(OT-Directory));
  $d = $dir.meta;
  is $d<name>, 'no-dir', $d<name>;
  like $d<path>, /:s Library $/, $d<path>;
  ok !$d<exists>, 'object does not exist';

  say $d.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/config.toml';
rmdir 't/Lib4';

exit(0);
