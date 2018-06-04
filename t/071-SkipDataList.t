use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::MetaConfig::SkipDataList;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::Cursor;

use BSON::Document;

#------------------------------------------------------------------------------
drop-send-to('mongodb');
drop-send-to('screen');
#modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
info-message("Test $?FILE start");

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');
my Str $db-name = 'meta071';
my Str $cl-name = 'meta071Cfg';

#-------------------------------------------------------------------------------
# setup config directory
mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
%*ENV<LIBRARY_CONFIG> = 't/Lib4';
my Str $filename = 't/Lib4/client-configuration.toml';
spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      server      = "localhost"
      port        = $p1

    [ library ]
      root-db     = "root071"
      user-db     = "$db-name"

    [ library.collections ]
      meta-data   = "meta071Data"
      meta-config = "$cl-name"

    #[ library.collections.root ]

    EOCFG

#initialize-library(:user-key<u1>);
initialize-library;

my MongoDB::Client $client := $Library::client;
my MongoDB::Database $database = $client.database($db-name);
$database.run-command: (dropDatabase => 1,);
my MongoDB::Collection $cl-cfg = $database.collection($cl-name);
my MongoDB::Cursor $cu;

#-------------------------------------------------------------------------------
# store a list of skip filter spec
subtest 'Insert skip specs', {

  my Library::MetaConfig::SkipDataList $c .= new;

  # try to insert some skip specs. case preservation but remove duplicates
  $c.set-skip-filter( <t1 T2 t3 t3>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<skip-filter>, )),
    :number-to-return(1)
  );

  my BSON::Document $doc = $cu.fetch;
  is-deeply $doc<skips>, [<T2 t1 t3>], "Skip specs inserted.";

  # insert new with some overlap
  $c.set-skip-filter( <t1 T55>, :!drop);
  is-deeply $c.get-skip-filter, [<T2 T55 t1 t3>],
    "Skip specs are '$c.get-skip-filter()'. Getter is used";
}

#-------------------------------------------------------------------------------
# filter using skip filter
subtest 'filter path with filter', {

  my Library::MetaConfig::SkipDataList $c .= new;

  ok $c.filter('/abc/def/T2'), "Path '/abc/def/T2' is filtered";
  nok $c.filter('/abc/def/pqr'), "Path '/abc/def/pqr' is not filtered";
}

#-------------------------------------------------------------------------------
# drop skip filter specs
subtest 'Drop skip specs', {

  my Library::MetaConfig::SkipDataList $c .= new;

  $c.set-skip-filter( <t3 t3>, :drop);
  is-deeply $c.get-skip-filter, [<T2 T55 t1>], "One skip spec deleted";

  $c.set-skip-filter( <T2 T55 t1>, :drop);
  is-deeply $c.get-skip-filter, [], "Rest is dropped too";
}

#-------------------------------------------------------------------------------
# store a list of skip filter spec
subtest 'Interesting skips', {

  my Library::MetaConfig::SkipDataList $c .= new;

  # insert real world skip specs. drop is by default False.
  $c.set-skip-filter( '\/\.git<-[/]>*', '\/\.precomp<|w>');
  diag "Skip filter set to: " ~ $c.get-skip-filter;

  my Str $p = '/home/mt/Project/.git/HEAD';
  ok $c.filter($p), "Path '$p' is filtered";
  $p = '/home/mt/Project/.gitignore';
  ok $c.filter($p), "Path '$p' is filtered";
  $p = '/home/mt/Perl6/lib/.precomp/';
  ok $c.filter($p), "Path '$p' is filtered";
  $p = '/home/mt/Perl6/lib/Library.pm6';
  nok $c.filter($p), "Path '$p' is not filtered";
}

#-------------------------------------------------------------------------------
done-testing;

$database.run-command: (dropDatabase => 1,);
$client.cleanup;

unlink 't/Lib4/client-configuration.toml';
unlink 't/Lib4/store-file-metadata.log';
rmdir 't/Lib4';
