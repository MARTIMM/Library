use v6;


#use MongoDB;
use Library;
use Library::MetaDB;
#use Library::Configuration;

#-------------------------------------------------------------------------------
#
package Library {
  constant $FAIL                = 0x0000;       # Failure db access
  constant $IS_STORED           = 0x0001;       # Metadata is stored
  constant $NOT_STORED          = 0x0002;       # Metadata is not stored
  constant $IS_UPDATED          = 0x0003;       # Metadata is updated
  constant $ALR_STORED          = 0x0004;       # Metadata is already in db


  #-----------------------------------------------------------------------------
  #
  class File-metadata-manager does Library::MetaDB {

#    my Str @source-locations;
    has Int $.status;


    method process-directory ( Str $document-path ) {
      $!status = $FAIL;

      my $f-io = $document-path.IO;
      my $name = $f-io.basename;
#say "PF: $document-path, $name";

      # search for it first
      #
      my $found_doc = self!name_in_db($document-path);
      if ?$found_doc {
        self.meta-update( $found_doc,
                          %( searchable => $f-io.x
                           )
                        );
         $!status = $IS_UPDATED;
      }

      else {
        # set if not found
        #
        self.meta-insert( %( name => $document-path,
                             searchable => $f-io.x,
                             type => 'directory',
                           )
                        );
        $!status = $IS_STORED;
      }
    }


    method process-file ( Str $document-path ) {
      $!status = $FAIL;

      my $f-io = $document-path.IO;
      my $name = $f-io.basename;
      my $extension = $f-io.extension;
      my $dirname = $f-io.dirname;

#say "PF: $document-path, $name, $type";

      # search for it first
      #
      my $found_doc = self!name_in_db($document-path);
      if ?$found_doc {
        self.meta-update( $found_doc,
                          %( size => $f-io.s,
                             executable => $f-io.x,
                             dirname => $dirname
                          )
                        );
        $!status = $IS_UPDATED;
      }

      else {
        # set if not found
        #
        self.meta-insert( %( name => $document-path,
                             extension => $extension,
                             type => 'file',
                             dirname => $dirname
                           )
                        );
        $!status = $IS_STORED;
      }
    }


    method !name_in_db ( Str $document-path --> Hash ) {
      my Hash $doc = self.meta-find-one({name => $document-path});
      return $doc;
    }
  }
}


