use v6;

use MongoDB;
use Library;
use Library::Configuration;

#------------------------------------------------------------------------------
#
package Library {

  role MetaDB {

    my $cfg = $Library::cfg;
    our $connection = MongoDB::Connection.new(
          :host($cfg.get('MongoDB_Server')),
          :port(Int($cfg.get('port')))
        );

    our $database = $connection.database($cfg.get('database'));
    our $collection = $database.collection($cfg.get('collections')<documents>);

    method meta-insert ( Hash $document ) {
      $collection.insert($document);
    }

    method meta-find-one ( Hash $document --> Hash ) {
      return $collection.find_one($document);
    }
  }

  #----------------------------------------------------------------------------
  #
  class File-metadata-manager does Library::MetaDB {

    my Str @source-locations;

    method process-directory ( Str $document-path ) {
#say "Server: ", $Library::cfg.get('MongoDB_Server');
      my $path = $document-path.IO.dir;
      my $name = $document-path.IO.basename;
      $name ~~ /\.(<-[^.]>+)$/;
      my $type = 'directory';
      
      # search for it first
      #
      if self._name_in_db($document-path) {
#        say "$type already stored";
      }
      
      else {

        # set if not found
        #
        self.meta-insert( %( name => $document-path,
                             type => $type
                           )
                        );
      }
    }

    method process-file ( Str $document-path ) {
#say "Server: ", $Library::cfg.get('MongoDB_Server');
      my $path = $document-path.IO.dir;
      my $name = $document-path.IO.basename;
      $name ~~ /\.(<-[^.]>+)$/;
      my $type = ~$/[0];

      # search for it first
      #
      if self._name_in_db($document-path) {
#        say "$type already stored";
      }
      
      else {
        # set
        #
        self.meta-insert( %( name => $document-path,
                             type => $type
                           )
                        );
      }
    }

    method _name_in_db ( Str $document-path --> Bool ) {
        my Hash $doc = self.meta-find-one({name => $document-path});
        return ?$doc;
    }
  }
}


