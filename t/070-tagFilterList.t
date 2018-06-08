use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::MetaConfig::TagFilterList;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::Cursor;

use BSON::Document;

#------------------------------------------------------------------------------
#drop-send-to('mongodb');
drop-send-to('screen');
#modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
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
      port        = $p1

    [ library ]
      root-db     = "root070"
      user-db     = "$db-name"
      loglevelfile    = "Info"
      loglevelscreen  = "Info"

    [ library.collections ]
      meta-data   = "meta070Data"
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
# Store a list of tags in the configuration collection
subtest 'Insert tags', {

  my Library::MetaConfig::TagFilterList $c .= new;

  # try to insert too small tag names. this will insert a new document
  # with an empty filter array.
  $c.set-tag-filter( <ta tb tc>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
  );

  my BSON::Document $doc = $cu.fetch;
  is-deeply $doc<tags>, [], "No tags inserted. All tags are too short";



  # try to insert mixed tag names. all are converted to lowercase,
  # sorted and made unique. this will update the filter list.
  $c.set-tag-filter( <TaB tac taa TaC>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
  );

  $doc = $cu.fetch;
  is $doc<config-type>, 'tag-filter', "Config type is tag-filter";
  is-deeply $doc<tags>, [<taa tab tac>], "tag list is set properly";

  $doc = $cu.fetch;
  nok $doc, 'There is only one record';



  # try to insert mixed tag names. Now add some overlap with existing tags.
  $c.set-tag-filter( <TaB TaC Pqr Xyz>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
    :number-to-return(1)
  );

  $doc = $cu.fetch;
  is-deeply $doc<tags>, [<pqr taa tab tac xyz>], "tag list is still ok";


  # get the tags list
  is-deeply $c.get-tag-filter, [<pqr taa tab tac xyz>],
    "tag list retrieved using get-tag-filter";
}

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
subtest 'Filter tags', {

  my Library::MetaConfig::TagFilterList $c .= new;

  # filter too small tags
  is-deeply $c.filter-tags([<ta tb>]), [], "Filtered all out";

  is-deeply $c.filter-tags([<taa tab Xab Xde>]), [<xab xde>],
    "Filtered 2 tags";
}

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
subtest 'Drop tags', {

  my Library::MetaConfig::TagFilterList $c .= new;

  # try to drop non existent tag names
  $c.set-tag-filter( <abc DeF>, :drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
  );

  my BSON::Document $doc = $cu.fetch;
  is-deeply $doc<tags>, [<pqr taa tab tac xyz>],
    "No tags dropped. Tags weren't there";



  # try to drop mixed tag names. all are converted to lowercase,
  # sorted and made unique before removal.
  $c.set-tag-filter( <TaB tab PQrs>, :drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
    :number-to-return(1)
  );

  $doc = $cu.fetch;
  is-deeply $doc<tags>, [<pqr taa tac xyz>], "dropped one tag from list";


  # try to drop the rest.
  $c.set-tag-filter( <pqr taa tac xyz>, :drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
    :number-to-return(1)
  );

  $doc = $cu.fetch;
  is-deeply $doc<tags>, [], "tag list now empty";
}

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
subtest 'Insert tags', {

  # drop the database to check if an insert operation works
  $database.run-command: (dropDatabase => 1,);
  my Library::MetaConfig::TagFilterList $c .= new;

  # try to insert tags on empty filter list. test database insert.
  $c.set-tag-filter( <taab bBax aaDE>, :!drop);
  is-deeply $c.get-tag-filter, [<aade bbax taab>],
    "Tags inserted in empty filter list";
}

#-------------------------------------------------------------------------------
done-testing;

$database.run-command: (dropDatabase => 1,);
$client.cleanup;

unlink 't/Lib4/client-configuration.toml';
unlink 't/Lib4/store-file-metadata.log';
rmdir 't/Lib4';
