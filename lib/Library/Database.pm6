use v6.c;

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
role Database {

  has MongoDB::Database $!database;
  has MongoDB::Collection $!collection handles <find>;

  #-----------------------------------------------------------------------------
  method init ( Str:D :$database-key!, Str:D :$collection-key! ) {

    my Library::Configuration $lcg := $Library::lib-cfg;

    $!database = $Library::client.database($lcg.config{$database-key});
    $!collection = $!database.collection($lcg.config<collection>{$collection-key});
  }

  #-----------------------------------------------------------------------------
  method insert ( Array $documents --> BSON::Document ) {

    $!database.run-command: (
      insert => $!collection.name,
      documents => $documents
    );
  }

  #-----------------------------------------------------------------------------
  method update ( Array $updates --> BSON::Document ) {

    $!database.run-command: (
      update => $!collection.name,
      updates => $updates,
      ordered => True,
    );
  }

  #-----------------------------------------------------------------------------
  method delete ( Array $deletes --> BSON::Document ) {

    $!database.run-command: (
      delete => $!collection.name,
      deletes => $deletes
    );
  }

  #-----------------------------------------------------------------------------
  method count ( List $query = () --> BSON::Document ) {

    my BSON::Document $req .= new;
    $req<count> = $!collection.name;
    $req<query> = $query if ?$query;
    $!database.run-command($req);
  }

  #-----------------------------------------------------------------------------
  method drop-database ( --> BSON::Document ) {

    $!database.run-command: (dropDatabase => 1,);
  }
}
