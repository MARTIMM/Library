use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
class Metadata::Object::Directory does Library::Metadata::Object {

  #----------------------------------------------------------------------------
  # Set the default informaton for a directory in the meta structure
  method specific-init-meta ( Str :$object, ObjectType :$type ) {

    my Str $path = $object.IO.absolute;
    my Str $dir = $object.IO.basename;
    $path ~~ s/ '/'? $dir $//;

    $!meta-data<name> = $dir;
    $!meta-data<path> = $path;
    $!meta-data<meta-type> = $type.Str;
    $!meta-data<exists> = $object.IO ~~ :r;
  }

  #----------------------------------------------------------------------------
  # Update database with the data in the meta structure.
  # Returns result document with at least key field 'ok'
  method update-meta ( ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the directory what to do.
    my BSON::Document $doc .= new: (:ok(1));
    my BSON::Document $query;

    # If file is found in db, we do not have to do anything
    if self.is-in-db: (
      name => $!meta-data<name>,
      path => $!meta-data<path>,
      type => OT-Directory,
      hostname => $!meta-data<hostname>,
    ) {

      info-message("Directory $!meta-data<name> found by name and path, no update");
    }

    # So if not found ...
    else {

      info-message("Directory $!meta-data<name> not found by name and path");

      if self.is-in-db( $query .= new: (
          name => $!meta-data<name>,
          type => OT-Directory,
          hostname => $!meta-data<hostname>,
        )
      ) {

        info-message("Directory $!meta-data<name> found by name only");

        # Check first if file from this search has an existing directory on disk
        # if so, modify the record found in the query.
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been moved, updated");

# What if query returns more of the same, is that possible?
            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            self!log-update-message($doc);
            last;
          }
        }
      }

      # directory may be renamed
      elsif self.is-in-db( $query .= new: (
          type => OT-Directory,
          path => $!meta-data<path>,
          hostname => $!meta-data<hostname>,
        )
      ) {

        info-message("Directory $!meta-data<name> found by path");

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

            self!log-update-message($doc);
            last;
          }
        }
      }

      # different directory
      else {

        info-message("$!meta-data<name> not found -> must be new, updated");

        $doc = self.insert: [$!meta-data];
      }
    }

#note "M::O::F: ", $doc.perl;
    $doc;
  }
}
