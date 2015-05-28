use v6;


use MongoDB::Connection;
use Library;
use Library::Configuration;

package Library {
  role Library::MetaDB {

    my $cfg = $Library::cfg;
    our $database = $Library::connection.database($cfg.get('database'));
    our $collection = $database.collection($cfg.get('collections')<documents>);

    method meta-insert ( Hash $document ) {
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
}

