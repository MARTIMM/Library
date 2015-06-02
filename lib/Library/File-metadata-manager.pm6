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


    method process-directory ( Str $document-path, Array $keys ) {
      $!status = $FAIL;

      my $f-io = $document-path.IO;
      my $accessed = ~$f-io.accessed;
      my $volume = $f-io.volume;

      # search for it first
      #
      my $found_doc = self!name_in_db($document-path);
      if ?$found_doc {
        my Hash $meta-data = {
          size          => $f-io.s,
          searchable    => $f-io.x,
          changed       => ~$f-io.changed,
          modified      => ~$f-io.modified,
        };

        $meta-data<keywords> = $keys if ?$keys;
        $meta-data<accessed> = $accessed if ?$accessed;
        $meta-data<volume> = $volume if ?$volume;

        self.meta-update( $found_doc, $meta-data);
        $!status = $IS_UPDATED;
      }

      else {
        # set if not found
        #
        my Hash $meta-data = {
          full-name     => $*SPEC.rel2abs($document-path),
          doc-type      => 'directory',
          file-name     => $f-io.basename,
          searchable    => $f-io.x,
          size          => $f-io.s,
          changed       => ~$f-io.changed,
          modified      => ~$f-io.modified,
        };

        $meta-data<keywords> = $keys if ?$keys;
        $meta-data<accessed> = $accessed if ?$accessed;
        $meta-data<volume> = $volume if ?$volume;

        self.meta-insert($meta-data);
        $!status = $IS_STORED;
      }
    }


    method process-file ( Str $document-path, Array $keys ) {
      $!status = $FAIL;

      my $f-io = $document-path.IO;
      my $accessed = ~$f-io.accessed;
      my $volume = $f-io.volume;

      # search for it first
      #
      my $found_doc = self!name_in_db($document-path);
      if ?$found_doc {
        my Hash $meta-data = {
          size          => $f-io.s,
          executable    => $f-io.x,
          changed       => ~$f-io.changed,
          modified      => ~$f-io.modified,
        };

        $meta-data<keywords> = $keys if ?$keys;
        $meta-data<accessed> = $accessed if ?$accessed;
        $meta-data<volume> = $volume if ?$volume;

        self.meta-update( $found_doc, $meta-data);
        $!status = $IS_UPDATED;
      }

      else {
        # set if not found
        #
        my Hash $meta-data = {
          full-name     => $*SPEC.rel2abs($document-path),
          extension     => $f-io.extension,
          doc-type      => 'file',
          dirname       => $f-io.dirname,
          file-name     => $f-io.basename,
          executable    => $f-io.x,
          size          => $f-io.s,
          changed       => ~$f-io.changed,
          modified      => ~$f-io.modified,
        };

        $meta-data<keywords> = $keys if ?$keys;
        $meta-data<accessed> = $accessed if ?$accessed;
        $meta-data<volume> = $volume if ?$volume;

        self.meta-insert($meta-data);
        $!status = $IS_STORED;
      }
    }


    method !name_in_db ( Str $document-path --> Hash ) {
      my Hash $doc = self.meta-find-one(
         { full-name => $*SPEC.rel2abs($document-path) }
      );
      return $doc;
    }
  }
}


