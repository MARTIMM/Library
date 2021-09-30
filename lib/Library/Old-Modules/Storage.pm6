use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::Cursor;

use BSON::Document;

#-------------------------------------------------------------------------------
# Purpose of this role is to search, insert and update the data in a database
class Storage {

  has MongoDB::Database $!database;
  has MongoDB::Collection $!collection;# handles <find>;
  has Str $!collection-key;
  has Bool $!use-lib-db;

  #-----------------------------------------------------------------------------
  # the database-key will be most of the time 'database' but the collectio-key
  # may vary. made this way for future flexibility. Mostly called from a
  # Library::Metadata::* class to set a specific database and collection
  submethod BUILD ( Str:D :$!collection-key, Bool :$!use-lib-db = False ) {
#note "dbo collection key: $!collection-key";

    self!test-connection;
  }

  #-----------------------------------------------------------------------------
  method insert ( Array:D $documents --> BSON::Document ) {

    return BSON::Document.new(:ok(0)) unless self!test-connection;

    $!database.run-command: (
      insert => $!collection.name,
      documents => $documents
    )
  }

  #-----------------------------------------------------------------------------
  method update ( Array:D $updates --> BSON::Document ) {

    return BSON::Document.new: (:ok(0)) unless self!test-connection;

    $!database.run-command: (
      update => $!collection.name,
      updates => $updates,
      ordered => True,
    )
  }

  #-----------------------------------------------------------------------------
  method delete ( Array:D $deletes --> BSON::Document ) {

    return BSON::Document.new: (:ok(0)) unless self!test-connection;

    $!database.run-command: (
      delete => $!collection.name,
      deletes => $deletes
    )
  }

  #-----------------------------------------------------------------------------
  multi method count ( List $query = () --> BSON::Document ) {

    return BSON::Document.new: (:ok(0)) unless self!test-connection;

    my BSON::Document $req .= new;
    $req<count> = $!collection.name;
    $req<query> = $query;
#note "count req 1: ", $req.perl;

    $!database.run-command($req)
  }

  multi method count (
    BSON::Document $query = BSON::Document.new
    --> BSON::Document
  ) {

    return BSON::Document.new: (:ok(0)) unless self!test-connection;

    my BSON::Document $req .= new;
    $req<count> = $!collection.name;
    $req<query> = $query;
#note "count req 2: ", $req.perl;

    my BSON::Document $doc = $!database.run-command($req);
#note "ret doc 2: ", $doc<ok>, ', ', $doc<n>;
    $doc
  }

  #-----------------------------------------------------------------------------
  method find (
    $query, Int :$limit = 0, Bool :$debug = False --> MongoDB::Cursor
  ) {

    return MongoDB::Cursor unless self!test-connection;

    my BSON::Document $req .= new;
    $req<find> = $!collection.name;
    $req<filter> = $query;
    $req<limit> = $limit;

    my MongoDB::Cursor $c = $!database.run-command( $req, :cursor);
#note "Find: ", $c.perl;# if $debug;

    $c
  }

#`{{
  #-----------------------------------------------------------------------------
  method documents (
    BSON::Document $find-result where ?*<cursor>
    --> Array
  ) {
    $find-result<cursor><firstBatch>
  }

  #-----------------------------------------------------------------------------
  method get-more (
    BSON::Document $find-result where ?*<cursor>
    --> BSON::Document
  ) {

    # if id = 0 there are no documents left to retrieve
    return BSON::Document unless $find-result<cursor><id>;

    my BSON::Document $req .= new;
    $req<getMore> = $find-result<cursor><id>;
    $req<collection> = $find-result<cursor><ns>;

    my $doc = $!database.run-command($req);
note "Get more: ", $doc.perl;

    $doc
  }
}}
  #-----------------------------------------------------------------------------
  method drop-collection ( --> BSON::Document ) {

    return BSON::Document.new: (:ok(0)) unless self!test-connection;

    $!database.run-command: (drop => $!collection.name,);
  }

  #-----------------------------------------------------------------------------
  method drop-database ( --> BSON::Document ) {

    return BSON::Document.new: (:ok(0)) unless self!test-connection;

    $!database.run-command: (dropDatabase => 1,);
  }

  #--[ Private methods ]--------------------------------------------------------
  method !test-connection ( --> Bool ) {

#note "\ntest conn: $!collection-key, ", $Library::client.defined;
    return False unless $Library::client.defined;

    my Library::Configuration $lcg := $Library::lib-cfg;
#note "\nprog config: ", $lcg.prog-config;
#note "\nlib config: ", $lcg.lib-config;

    # get database and collection name from configuration
    my Str $db-name = $lcg.database-name(:$!use-lib-db);
    my Str $col-name = $lcg.collection-name( $!collection-key, :$!use-lib-db);
#note "lcg: $db-name, $col-name";

    # create database with client and get collection
    $!database = $Library::client.database($db-name);
    $!collection = $!database.collection($col-name);

note "Col: ", $!collection.full-collection-name;

    True
  }
}
