use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
class Metadata::Object::File does Library::Metadata::Object {

  #----------------------------------------------------------------------------
  # Set the default informaton for a file in the meta structure
  method specific-init-meta ( Str :$object, ObjectType :$type ) {

    my Str $path = $object.IO.absolute;
    my Str $file = $object.IO.basename;
    my Str $extension = $object.IO.extension;
    $path ~~ s/ '/'? $file $//;

    $!meta-data<name> = $file;
    $!meta-data<content-type> = $extension;
    $!meta-data<path> = $path;
    $!meta-data<meta-type> = $type.Str;
    $!meta-data<exists> = $object.IO ~~ :r;
    $!meta-data<content-sha1> = self!sha1-content($object);

    info-message("metadata set for $object");
    debug-message($!meta-data.perl);
  }

  #----------------------------------------------------------------------------
  # Update database with the data in the meta structure.
  # Returns result document with at least key field 'ok'
  method update-meta ( --> BSON::Document ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the file what to do.
    my BSON::Document $doc .= new: (:ok(1));
    my BSON::Document $query;

    # If file is found in db, we do not have to do anything
    if self.is-in-db: (
      name => $!meta-data<name>,
      path => $!meta-data<path>,
      meta-type => ~OT-File,
      content-sha1 => $!meta-data<content-sha1>,
      hostname => $!meta-data<hostname>,
    ) {

      info-message("File $!meta-data<name> found by name, path and content, no update");
    }

    # So if not found ...
    else {

      info-message("File $!meta-data<name> not found by name, path, content");

#`{{
      # File maybe moved
      $query .= new: (
          name => $!meta-data<name>,
          meta-type => ~OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      );
}}
      if self.is-in-db( $query .= new: (
          name => $!meta-data<name>,
          meta-type => ~OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
        )
      ) {

        info-message("File $!meta-data<name> found by name and content");

        # Check first if file from this search has an existing file
        # if so, do not modify the record.
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been moved, updated");

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            if $doc<ok> == 1 {
              info-message("meta data of $!meta-data<name> updated");
            }

            else {
              error-message("updating meta data of $!meta-data<name> failed, err: $doc<errmsg>");
            }

            last;
          }
        }
      }

      # File may be renamed
      elsif self.is-in-db( $query .= new: (
          meta-type => ~OT-File,
          path => $!meta-data<path>,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
        )
      ) {

        info-message("File $!meta-data<name> found by name. path and content");

        # Check first if file from this search has an existing file
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been renamed, updated");

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            if $doc<ok> == 1 {
              info-message("meta data of $!meta-data<name> updated");
            }

            else {
              error-message("updating meta data of $!meta-data<name> failed, err: $doc<errmsg>");
            }

            last;
          }
        }
      }

      # File may be moved and renamed
      elsif self.is-in-db( $query .= new: (
          meta-type => ~OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      )) {

        info-message("File $!meta-data<name> found by its content");

        # Check first if file from this search has an existing file
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been renamed and moved, updated");

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            if $doc<ok> == 1 {
              info-message("meta data of $!meta-data<name> updated");
            }

            else {
              error-message("updating meta data of $!meta-data<name> failed, err: $doc<errmsg>");
            }

            last;
          }
        }
      }

      # File may be modified
      elsif self.is-in-db( $query .= new: (
          name => $!meta-data<name>,
          meta-type => ~OT-File,
          path => $!meta-data<path>,
          hostname => $!meta-data<hostname>,
      )) {

        info-message("File $!meta-data<name> found by name and path");

        # Check first if file from this search has an existing file
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been modified or deleted, updated");

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            if $doc<ok> == 1 {
              info-message("meta data of $!meta-data<name> updated");
            }

            else {
              error-message("updating meta data of $!meta-data<name> failed, err: $doc<errmsg>");
            }

            last;
          }
        }
      }

      # different file
      else {
        info-message("$!meta-data<name> not found -> must be new, updated");

        $doc = self.insert: [$!meta-data];
      }
    }

    # return database operations result
    $doc;
  }
}
