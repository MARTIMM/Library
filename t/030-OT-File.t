use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Metadata::Database;
use Library::Metadata::Object::File;
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
    meta-data = 'meta030'

  EOCFG

initialize-library();

#-------------------------------------------------------------------------------
subtest 'OT File', {

  my Library::Metadata::Database $dbo .= new;
  my Library::Metadata::Object::File $f;

  $f .= new( :$dbo, :object<t/030-OT-File.t>, :type(OT-File));
  my BSON::Document $d = $f.meta;
  is $d<name>, '030-OT-File.t', $d<name>;
  is $d<extension>, 't', $d<extension>;
  like $d<path>, /:s t $/, $d<path>;
  ok $d<exists>, 'object exists';
  ok $d<content-sha1>, 'sha calculated on content';

#  say $d.perl;

  $f .= new( :$dbo, :object<t/other-file.t>, :type(OT-File));
  $d = $f.meta;
  is $d<name>, 'other-file.t', $d<name>;
  like $d<path>, /:s t $/, $d<path>;
  ok !$d<exists>, 'object does not exist';
  ok !$d<content-sha1>, 'no sha on content';

#  say $d.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/config.toml';
rmdir 't/Lib4';

exit(0);
