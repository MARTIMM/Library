use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Metadata::Object;
use Library::Metadata::Object::File;

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
      server      = "localhost"
      port        = "$p1"

    #[ connection.user.u1 ]
    #  user        = "marcel"
    #  password    = "hoeperdepoep"
    #  database    = "test-lib"

    [ library ]
      root-db    = "test"
      user-db    = "meta50"

    [ library.collections ]
      meta-data   = "meta50-data"

    [ library.collections.root ]
      meta-config = "meta050-cfg"

    EOCFG

#initialize-library(:user-key<u1>);
initialize-library;


#------------------------------------------------------------------------------
subtest 'User added metadata', {

  my $filename = 't/030-OT-File.t';
  diag "update metadata with $filename";
  my Library::Metadata::Object::File $lmo .= new(:object($filename));

  diag "get metadata";
  my BSON::Document $udata = $lmo.get-metameta;
  $udata<note> = 'This is a test file';
  $udata<keys> = [< test library>];
  $lmo.set-metameta($udata);

  for $lmo.find( :criteria( name => '030-OT-File.t',)) -> $doc {
#note "Doc 0: ", $doc.perl;
    is $doc<name>, '030-OT-File.t', 'file stored';
    is $doc<user-meta><note>, 'This is a test file', 'note found too';
  }
}

#------------------------------------------------------------------------------
subtest 'Moving files around', {

  my $filename = 't/abc.def';
  diag "set $filename and provide content";
  spurt $filename, 'hoeperdepoep zat op de stoep';

  my Library::Metadata::Object::File $lmo;
  $lmo .= new(:object($filename));

  my BSON::Document $udata = $lmo.get-metameta(:subdoc<program-meta>);
  $udata<note> = 'file to be manipulated';
  $udata<keys> = [< moved renamed edited>];
  $lmo.set-metameta( $udata, :subdoc<program-meta>);

  diag "rename $filename to 't/ghi.xyz'";
  $filename.IO.rename('t/ghi.xyz');
  $filename = 't/ghi.xyz';
  $lmo .= new(:object($filename));
  diag "Meta data of 't/ghi.xyz': " ~ $lmo.meta.perl;
#  diag $lmo.find( :criteria(:name<ghi.xyz>,)).perl;
  for $lmo.find( :criteria(:name<ghi.xyz>,)) -> $doc {
#diag "Doc 0: ", $doc.perl;
    is $doc<name>, 'ghi.xyz', 'file renamed';
    is $doc<program-meta><note>, 'file to be manipulated', 'note found too';
  }


  diag "move $filename to 't/Lib4/ghi.xyz'";
  $filename.IO.move('t/Lib4/ghi.xyz') unless $filename eq 't/Lib4/ghi.xyz';
  $filename = 't/Lib4/ghi.xyz';
  $lmo .= new(:object($filename));
  for $lmo.find( :criteria( name => 'ghi.xyz',)) -> $doc {
#diag "Doc 1: " ~ $doc.perl;
    like $doc<path>, / 't/Lib4' /, 'file moved';
    is-deeply $doc<program-meta><keys>, [< moved renamed edited>], 'keys found';
  }

  diag "move and rename $filename to 't/ghi.pqr'";
  my Str $content-sha1;
  $filename.IO.move('t/ghi.pqr') unless $filename eq 't/ghi.pqr';
  $filename = 't/ghi.pqr';
  $lmo .= new( :object($filename), :type(OT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {
diag "Doc 2: " ~ $doc.perl;
    next unless $doc<path> ~~ m/ 't' $/;

    like $doc<path>, / '/t' /, 'file moved and renamed';
    is $doc<program-meta><keys>[1], 'renamed', 'one key tested';
    $content-sha1 = $doc<content-sha1>;
  }

  diag "modify content of $filename";
  spurt $filename, 'en laten we vrolijk wezen';
  $lmo .= new( :object($filename), :type(OT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {

diag "Doc 3: " ~ $doc.perl;
    next unless $doc<path> ~~ m/ 't' $/;

    like $doc<path>, / '/t' /, 'path still the same';
    is $doc<program-meta><keys>[0], 'moved', 'another key tested';
    nok $content-sha1 ne $doc<content-sha1>, 'Content changed';
    $content-sha1 = $doc<content-sha1>;
  }

  diag "ghi.pqr created in t/Lib4 directory with same content";
  spurt "t/Lib4/ghi.pqr", "en laten we vrolijk wezen";
  $lmo .= new( :object("t/Lib4/ghi.pqr"), :type(OT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {
diag "Doc 4: " ~ $doc.perl;
    next unless $doc<path> ~~ m/ 't/Lib4' $/;

    like $doc<path>, / '/t/Lib4' /, 'file created anew';
    nok $content-sha1 eq $doc<content-sha1>, 'Content same as other file';
  }

  diag "$filename removed";
  unlink $filename;
  $lmo .= new( :object($filename), :type(OT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {
    next unless $doc<path> ~~ m/ 't' $/;

diag "Doc 5: " ~ $doc.perl;
    is $doc<exists>, False, 'exists updated';
  }


#  my BSON::Document $d = $lmo.drop-collection;
#  note $d.perl;
}

#------------------------------------------------------------------------------
CATCH {
  default {
    .note;
  }
}

#------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/ghi.xyz';

unlink 't/ghi.pqr';
unlink 't/Lib4/client-configuration.toml';
unlink 't/Lib4/store-file-metadata.log';
unlink 't/Lib4/ghi.pqr';
rmdir 't/Lib4';
