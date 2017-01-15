use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Metadata::Database;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
set-logfile($*OUT);
set-exception-process-level(MongoDB::Severity::Info);
info-message("Test $?FILE start");

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

  my $filename = 't/030-OT-File.t';
  my Library::Metadata::Database $mdb .= new;
  my Library::Metadata::Object $lmo = $mdb.update-meta(
    :object($filename), :type(OT-File)
  );

  my BSON::Document $udata = $lmo.get-user-metadata;
  $udata<note> = 'This is a test file';
  $udata<keys> = [ < test library>];
  $lmo.set-user-metadata($udata).perl;

  for $mdb.find( :criteria( name => '030-OT-File.t',)) -> $doc {
#say "Doc 0: ", $doc.perl;
    is $doc<name>, '030-OT-File.t', 'file stored';
    is $doc<user-data><note>, 'This is a test file', 'note found too';
  }
}

#-------------------------------------------------------------------------------
subtest 'Moving files around', {

  my $filename = 't/abc.def';
  spurt $filename, 'hoeperdepoep zat op de stoep';
  diag "set $filename and provide content";

  my Library::Metadata::Database $mdb .= new;
  my Library::Metadata::Object $lmo;
  $lmo = $mdb.update-meta( :object($filename), :type(OT-File));

  my BSON::Document $udata = $lmo.get-user-metadata;
  $udata<note> = 'file to be manipulated';
  $udata<keys> = [< moved renamed edited>];
  $lmo.set-user-metadata($udata).perl;

  diag "rename $filename to 't/ghi.xyz'";
  $filename.IO.rename('t/ghi.xyz');
  $filename = 't/ghi.xyz';
  $lmo = $mdb.update-meta( :object($filename), :type(OT-File));
  for $mdb.find( :criteria( name => 'ghi.xyz',)) -> $doc {
#say "Doc 1: ", $doc.perl;
    is $doc<name>, 'ghi.xyz', 'file renamed';
    is $doc<user-data><note>, 'file to be manipulated', 'note found too';
  }

  diag "move $filename to 't/Lib4/ghi.xyz'";
  $filename.IO.move('t/Lib4/ghi.xyz');
  $filename = 't/Lib4/ghi.xyz';
  $lmo = $mdb.update-meta( :object($filename), :type(OT-File));
  for $mdb.find( :criteria( name => 'ghi.xyz',)) -> $doc {
#say "Doc 1: ", $doc.perl;
    like $doc<path>, / 't/Lib4' /, 'file moved';
    is-deeply $doc<user-data><keys>, [< moved renamed edited>], 'keys found';
  }

  diag "move and rename $filename to 't/ghi.pqr'";
  $filename.IO.move('t/ghi.pqr');
  $filename = 't/ghi.pqr';
  $lmo = $mdb.update-meta( :object($filename), :type(OT-File));
  for $mdb.find( :criteria( name => 'ghi.xyz',)) -> $doc {
#say "Doc 1: ", $doc.perl;
    like $doc<path>, / 't/Lib4' /, 'file moved';
    is $doc<user-data><keys>[1], 'renamed', 'one key tested';
  }

  diag "modify content of $filename";
  spurt $filename, 'en laten we vrolijk wezen';
  $lmo = $mdb.update-meta( :object($filename), :type(OT-File));
  for $mdb.find( :criteria( name => 'ghi.xyz',)) -> $doc {
#say "Doc 1: ", $doc.perl;
    like $doc<path>, / 't/Lib4' /, 'file modified';
    is $doc<user-data><keys>[0], 'moved', 'another key tested';
  }

  diag "$filename removed";
  unlink $filename;
  $lmo = $mdb.update-meta( :object($filename), :type(OT-File));
  for $mdb.find( :criteria( name => 'ghi.xyz',)) -> $doc {
say "Doc 1: ", $doc.perl;
    is $doc<exist>, False, 'exist updated';
  }
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/config.toml';
rmdir 't/Lib4';

exit(0);
