use v6;

use MongoDB;
use Library;
#use Library::Configuration;

#-------------------------------------------------------------------------------
#
package Library {
  constant $FAIL                = 0x0000;       # Failure db access
  constant $IS_STORED           = 0x0001;       # Metadata is stored
  constant $NOT_STORED          = 0x0002;       # Metadata is not stored
  constant $IS_UPDATED          = 0x0003;       # Metadata is updated
  constant $ALR_STORED          = 0x0004;       # Metadata is already in db

  role MetaDB {

    my $cfg = $Library::cfg;
    our $database = $Library::connection.database($cfg.get('database'));
    our $collection = $database.collection($cfg.get('collections')<documents>);

    method meta-insert ( Hash $document ) {
      $collection.insert($document);
    }

    method meta-find-one ( Hash $document --> Hash ) {
      return $collection.find_one($document);
    }
  }

  #-----------------------------------------------------------------------------
  #
  class File-metadata-manager does Library::MetaDB {

#    my Str @source-locations;
    has Int $.status;

    method process-directory ( Str $document-path ) {
      $!status = $FAIL;
#say "Server: ", $Library::cfg.get('MongoDB_Server');
      my $path = $document-path.IO.dir;
      my $name = $document-path.IO.basename;
      $name ~~ /\.(<-[^.]>+)$/;
      my $type = 'directory';
      
      # search for it first
      #
      if self._name_in_db($document-path) {
        $!status = $ALR_STORED;
      }
      
      else {
        # set if not found
        #
        self.meta-insert( %( name => $document-path,
                             type => $type
                           )
                        );
        $!status = $IS_STORED;
      }
    }

    method process-file ( Str $document-path ) {
      $!status = $FAIL;
#say "Server: ", $Library::cfg.get('MongoDB_Server');
      my $path = $document-path.IO.dir;
      my $name = $document-path.IO.basename;
      $name ~~ /\.(<-[^.]>+)$/;
      my $type = ~$/[0];

      # search for it first
      #
      if self._name_in_db($document-path) {
        $!status = $ALR_STORED;
      }

      else {
        # set if not found
        #
        self.meta-insert( %( name => $document-path,
                             type => $type
                           )
                        );
        $!status = $IS_STORED;
      }
    }

    method _name_in_db ( Str $document-path --> Bool ) {
      my Hash $doc = self.meta-find-one({name => $document-path});
      return ?$doc;
    }
  }
}


