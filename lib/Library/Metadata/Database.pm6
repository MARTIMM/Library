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
# Purpose of this role is to search, insert and update the data in the library
role Metadata::Database {

  has MongoDB::Database $!database;
  has MongoDB::Collection $!collection handles <find>;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    my Library::Configuration $lcg := $Library::lib-cfg;

    $lcg.config<database> = 'Library' unless ?$lcg.config<database>;
    $lcg.config<collection><meta-data> = 'meta-data'
      unless ?$lcg.config<meta-data>;

    $!database = $Library::client.database($lcg.config<database>);
    $!collection = $!database.collection($lcg.config<collection><meta-data>);
  }

  #-----------------------------------------------------------------------------
  method insert ( *@documents --> BSON::Document ) {

    $!database.run-command: (
      insert => $!collection.name,
      documents => [ |@documents, ]
    );
  }

  #-----------------------------------------------------------------------------
  method update ( $found_document, $modifications ) {
#say "C: $collection";
#    $collection.update( $found_document, {'$set' => $modifications});
  }

  #-----------------------------------------------------------------------------
  method delete ( *@deletes --> BSON::Document ) {

say @deletes.perl;
    $!database.run-command: (
      delete => $!collection.name,
      deletes => [ |@deletes, ]
    );
  }
}

