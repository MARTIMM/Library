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
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');
my Str $db-name = 'meta070';
my Str $cl-name = 'meta070Cfg';

#-------------------------------------------------------------------------------
# setup config directory
my Str $dir = 't/Meta070';
mkdir $dir, 0o700 unless $dir.IO ~~ :d;
%*ENV<LIBRARY_CONFIG> = $dir;
my Str $filename = $dir ~ '/client-configuration.toml';
spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      server          = "localhost"
      port            = $p1

    [ library ]
      user-db         = "$db-name"
      loglevelfile    = "Info"
      loglevelscreen  = "Info"

    [ library.collections ]
      meta-config     = "$cl-name"

    EOCFG

#initialize-library(:refine-key<u1>);
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
  $c.set-filter( <ta tb tc>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
  );

  my BSON::Document $doc = $cu.fetch;
  is-deeply $doc<tags>, [], "No tags inserted. All tags are too short";



  # try to insert mixed tag names. all are converted to lowercase,
  # sorted and made unique. this will update the filter list.
  $c.set-filter( <TaB tac taa TaC>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
  );

  $doc = $cu.fetch;
  is $doc<config-type>, 'tag-filter', "Config type is tag-filter";
  is-deeply $doc<tags>, [<taa tab tac>], "tag list is set properly";

  $doc = $cu.fetch;
  nok $doc, 'There is only one record';



  # try to insert mixed tag names. Now add some overlap with existing tags.
  $c.set-filter( <TaB TaC Pqr Xyz>, :!drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
    :number-to-return(1)
  );

  $doc = $cu.fetch;
  is-deeply $doc<tags>, [<pqr taa tab tac xyz>], "tag list is still ok";


  # get the tags list
  is-deeply $c.get-filter, [<pqr taa tab tac xyz>],
    "tag list retrieved using get-filter";
}

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
subtest 'Filter tags', {

  my Library::MetaConfig::TagFilterList $c .= new;

  # filter too small tags
  is-deeply $c.filter([<ta tb>]), [], "Filtered all out";

  is-deeply $c.filter([<taa tab Xab Xde>]), [<xab xde>],
    "Filtered 2 tags";
}

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
subtest 'Drop tags', {

  my Library::MetaConfig::TagFilterList $c .= new;

  # try to drop non existent tag names
  $c.set-filter( <abc DeF>, :drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
  );

  my BSON::Document $doc = $cu.fetch;
  is-deeply $doc<tags>, [<pqr taa tab tac xyz>],
    "No tags dropped. Tags weren't there";



  # try to drop mixed tag names. all are converted to lowercase,
  # sorted and made unique before removal.
  $c.set-filter( <TaB tab PQrs>, :drop);

  $cu = $cl-cfg.find(
    :criteria( (:config-type<tag-filter>, )),
    :number-to-return(1)
  );

  $doc = $cu.fetch;
  is-deeply $doc<tags>, [<pqr taa tac xyz>], "dropped one tag from list";


  # try to drop the rest.
  $c.set-filter( <pqr taa tac xyz>, :drop);

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
  $c.set-filter( <taab bBax aaDE>, :!drop);
  is-deeply $c.get-filter, [<aade bbax taab>],
    "Tags inserted in empty filter list";
}

#-------------------------------------------------------------------------------
done-testing;

$database.run-command: (dropDatabase => 1,);
$client.cleanup;

unlink $dir ~ '/client-configuration.toml';
unlink $dir ~ '/library.log';
rmdir $dir;
