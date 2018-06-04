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
  has MongoDB::Collection $!collection handles <find>;

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
    $req<query> = $query if ?$query;

    $!database.run-command($req)
  }

  multi method count (
    BSON::Document $query = BSON::Document.new
    --> BSON::Document
  ) {

    my BSON::Document $req .= new;
    $req<count> = $!collection.name;
    $req<query> = $query if ?$query;

    $!database.run-command($req)
  }

  #-----------------------------------------------------------------------------
  method drop-collection ( --> BSON::Document ) {

    $!database.run-command: (drop => $!collection.name,);
  }

  #-----------------------------------------------------------------------------
  method drop-database ( --> BSON::Document ) {

    $!database.run-command: (dropDatabase => 1,);
  }
}
