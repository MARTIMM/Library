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

      # search for it first
      #
      my $found_doc = self!name_in_db($document-path);
      if ?$found_doc {
        self.meta-update( $found_doc,
                          %( size               => $f-io.s,
                             searchable         => $f-io.x,
                             accessed           => ~$f-io.accessed,
                             changed            => ~$f-io.changed
                           )
                        );
         $!status = $IS_UPDATED;
      }

      else {
        # set if not found
        #
        self.meta-insert( %( full-name          => $document-path,
                             doc-type           => 'directory',
                             searchable         => $f-io.x,
                             file-name          => $f-io.basename,
                             size               => $f-io.s,
                             accessed           => ~$f-io.accessed,
                             changed            => ~$f-io.changed
                           )
                        );
        $!status = $IS_STORED;
      }
    }


    method process-file ( Str $document-path ) {
      $!status = $FAIL;

      my $f-io = $document-path.IO;

      # search for it first
      #
      my $found_doc = self!name_in_db($document-path);
      if ?$found_doc {
        self.meta-update( $found_doc,
                          %( size               => $f-io.s,
                             executable         => $f-io.x,
                             accessed           => ~$f-io.accessed,
                             changed            => ~$f-io.changed
                           )
                        );
        $!status = $IS_UPDATED;
      }

      else {
        # set if not found
        #
        self.meta-insert( %( full-name          => $document-path,
                             extension          => $f-io.extension,
                             doc-type           => 'file',
                             dirname            => $f-io.dirname,
                             file-name          => $f-io.basename,
                             size               => $f-io.s,
                             executable         => $f-io.x,
                             accessed           => ~$f-io.accessed,
                             changed            => ~$f-io.changed
                           )
                        );
        $!status = $IS_STORED;
      }
    }


    method !name_in_db ( Str $document-path --> Hash ) {
      my Hash $doc = self.meta-find-one({ full-name => $document-path });
      return $doc;
    }
  }
}


