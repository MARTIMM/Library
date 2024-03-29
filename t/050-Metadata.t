use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::MetaData;
use Library::MetaData::File;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');
my Str $dir = 't/Meta050';

# setup config directory
mkdir $dir, 0o700 unless $dir.IO ~~ :d;
%*ENV<LIBRARY_CONFIG> = $dir;
my Str $filename = $dir ~ '/client-configuration.toml';
spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      server          = "localhost"
      port            = $p1

    [ library ]
      root-db         = "test"
      user-db         = "meta050"
      logfile         = "meta050.log"
      loglevelfile    = "Info"
      loglevelscreen  = "Info"

    [ library.collections ]
      meta-data       = "meta050Data"
      meta-config     = "meta050Cfg"

    #[ library.collections.root ]

    EOCFG

#initialize-library(:refine-key<u1>);
initialize-library;


#-------------------------------------------------------------------------------
subtest 'User added metadata', {

  my $filename = 't/030-MT-File.t';
  diag "update metadata with $filename";
  my Library::MetaData::File $lmo .= new(:object($filename));
  diag "get metadata";
  my BSON::Document $udata = $lmo.get-metameta;
  $udata<note> = 'This is a test file';
  $udata<keys> = [< test library>];
  $lmo.set-metameta($udata);

  for $lmo.find( :criteria( name => '030-MT-File.t',)) -> $doc {
#note "Doc 0: ", $doc.perl;
    is $doc<name>, '030-MT-File.t', 'file stored';
    is $doc<user-meta><note>, 'This is a test file', 'note found too';
  }
}

#-------------------------------------------------------------------------------
subtest 'Moving files around', {

  my $filename = 't/abc.def';
  diag "set $filename and provide content";
  spurt $filename, 'hoeperdepoep zat op de stoep';

  my Library::MetaData::File $lmo;
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


  diag "move $filename to $dir/ghi.xyz'";
  $filename.IO.move($dir ~ '/ghi.xyz') unless $filename eq $dir ~ '/ghi.xyz';
  $filename = $dir ~ '/ghi.xyz';
  $lmo .= new(:object($filename));
  for $lmo.find( :criteria( name => 'ghi.xyz',)) -> $doc {
#diag "Doc 1: " ~ $doc.perl;
    like $doc<path>, / $dir /, 'file moved';
    is-deeply $doc<program-meta><keys>, [< moved renamed edited>], 'keys found';
  }

  diag "move and rename $filename to 't/ghi.pqr'";
  my Str $content-sha1;
  $filename.IO.move('t/ghi.pqr') unless $filename eq 't/ghi.pqr';
  $filename = 't/ghi.pqr';
  $lmo .= new( :object($filename), :type(MT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {
diag "Doc 2: " ~ $doc.perl;
    next unless $doc<path> ~~ m/ 't' $/;

    like $doc<path>, / '/t' /, 'file moved and renamed';
    is $doc<program-meta><keys>[1], 'renamed', 'one key tested';
    $content-sha1 = $doc<content-sha1>;
  }

  diag "modify content of $filename";
  spurt $filename, 'en laten we vrolijk wezen';
  $lmo .= new( :object($filename), :type(MT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {

diag "Doc 3: " ~ $doc.perl;
    next unless $doc<path> ~~ m/ 't' $/;

    like $doc<path>, / '/t' /, 'path still the same';
    is $doc<program-meta><keys>[0], 'moved', 'another key tested';
    nok $content-sha1 ne $doc<content-sha1>, 'Content changed';
    $content-sha1 = $doc<content-sha1>;
  }

  diag "ghi.pqr created in $dir directory with same content";
  spurt "$dir/ghi.pqr", "en laten we vrolijk wezen";
  $lmo .= new( :object("$dir/ghi.pqr"), :type(MT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {
diag "Doc 4: " ~ $doc.perl;
    next unless $doc<path> ~~ m/ $dir $/;

    like $doc<path>, / $dir /, 'file created anew';
    nok $content-sha1 eq $doc<content-sha1>, 'Content same as other file';
  }

  diag "$filename removed";
  unlink $filename;
  $lmo .= new( :object($filename), :type(MT-File));
  for $lmo.find( :criteria( name => 'ghi.pqr',)) -> $doc {
    next unless $doc<path> ~~ m/ 't' $/;

diag "Doc 5: " ~ $doc.perl;
    is $doc<exists>, False, 'exists updated';
  }


#  my BSON::Document $d = $lmo.drop-collection;
#  note $d.perl;
}

#-------------------------------------------------------------------------------
CATCH {
  default {
    .note;
  }
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/ghi.xyz';
unlink 't/ghi.pqr';
#unlink $dir ~ '/client-configuration.toml';
#unlink $dir ~ '/library.log';
unlink $dir ~ '/ghi.pqr';
#rmdir $dir;
