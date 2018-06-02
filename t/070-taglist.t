use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Config::TagsList;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::Cursor;

use BSON::Document;

#------------------------------------------------------------------------------
#drop-send-to('mongodb');
#drop-send-to('screen');
modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
info-message("Test $?FILE start");

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');
my Str $db-name = 'meta070';
my Str $cl-name = 'meta070Cfg';

#-------------------------------------------------------------------------------
# setup config directory
mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
%*ENV<LIBRARY_CONFIG> = 't/Lib4';
my Str $filename = 't/Lib4/client-configuration.toml';
spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      server      = "localhost"
      port        = "$p1"

    [ library ]
      root-db     = "root070"
      user-db     = "$db-name"

    [ library.collections ]
      meta-data   = "meta070Data"
      meta-config = "$cl-name"

    #[ library.collections.root ]

    EOCFG

#initialize-library(:user-key<u1>);
initialize-library;

my MongoDB::Client $client := $Library::client;
my MongoDB::Database $database = $client.database($db-name);
my MongoDB::Collection $cl-cfg = $database.collection($cl-name);
my MongoDB::Cursor $cu;

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
subtest 'tags inserts', {

  my Library::Config::TagsList $c .= new;
  $c.set-tag-filter( <t1 t2 t3>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
#    :number-to-return(1)
  );

  my BSON::Document $doc = $cu.fetch;
  ok !$doc, "No tags inserted. All tags are too short";



  $c.set-tag-filter( <t1a t2b t3c>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
#    :number-to-return(1)
  );

  $doc = $cu.fetch;
#note "DR: ", $doc.perl;
#  is-deeply $doc<tag-filter><tags>, <t1a t2b t3c>, "tag list is set properly";
}

#-------------------------------------------------------------------------------
done-testing;

unlink 't/Lib4/client-configuration.toml';
rmdir 't/Lib4';
