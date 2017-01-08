use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;

use BSON::Document;

#-------------------------------------------------------------------------------
# Purpose of this role is to search, insert and update the data in the library
role Library::Metadata::Database {

  has MongoDB::Database $!database;
  has MongoDB::Collection $!collection;

  submethod BUILD ( ) {

    my Library::Configuration $lcg := $Library::library-config;

    $lcg.config<database> = 'Library' unless ?$lcg.config<database>;
    $lcg.config<meta-data> = 'meta-data' unless ?$lcg.config<meta-data>;

    $!database = $Library::client.database($lcg.config<database>);
    $!collection = $!database.collection($lcg.config<meta-data>);
  }

  method meta-insert ( BSON::Document $document ) {
    $collection.insert($document);
  }

  method meta-find-one ( Hash $document --> Hash ) {
    return $collection.find_one($document);
  }

  method meta-update ( $found_document, $modifications ) {
#say "C: $collection";
    $collection.update( $found_document, {'$set' => $modifications});
  }
}

