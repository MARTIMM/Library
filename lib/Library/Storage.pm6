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

  #-----------------------------------------------------------------------------
  # the database-key will be most of the time 'database' but the collectio-key
  # may vary. made this way for future flexibility. Mostly called from a
  # Library::Metadata::* class to set a specific database and collection
  submethod BUILD ( Str:D :$collection-key, Bool :$root = False ) {

    my Library::Configuration $lcg := $Library::lib-cfg;
    my Str $db-name = $lcg.database-name(:$root);
    my Str $col-name = $lcg.collection-name( $collection-key, :$root);

    $!database = $Library::client.database($db-name);
    $!collection = $!database.collection($col-name);
  }

  #-----------------------------------------------------------------------------
  method insert ( Array:D $documents --> BSON::Document ) {

    $!database.run-command: (
      insert => $!collection.name,
      documents => $documents
    )
  }

  #-----------------------------------------------------------------------------
  method update ( Array:D $updates --> BSON::Document ) {

    $!database.run-command: (
      update => $!collection.name,
      updates => $updates,
      ordered => True,
    )
  }

  #-----------------------------------------------------------------------------
  method delete ( Array:D $deletes --> BSON::Document ) {

    $!database.run-command: (
      delete => $!collection.name,
      deletes => $deletes
    )
  }

  #-----------------------------------------------------------------------------
  multi method count ( List $query = () --> BSON::Document ) {

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

    $!database.run-command: (drop => $!collection.name,);
  }

  #-----------------------------------------------------------------------------
  method drop-database ( --> BSON::Document ) {

    $!database.run-command: (dropDatabase => 1,);
  }
}
