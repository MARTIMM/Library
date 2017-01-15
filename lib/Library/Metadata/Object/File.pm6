use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
class Metadata::Object::File does Library::Metadata::Object {

  #-----------------------------------------------------------------------------
  # $!metadata and $!dbo are defined in Library::Metadata::Object and
  # initialized in BUILD. BUILD calls init-meta to generated the metadata.
  method init-meta ( Str :$object, ObjectType :$type ) {

    my Str $path = $object.IO.abspath;
    my Str $file = $object.IO.basename;
    my Str $extension = $object.IO.extension;
    $path ~~ s/ '/'? $file $//;

    $!meta-data<name> = $file;
    $!meta-data<extension> = $extension;
    $!meta-data<path> = $path;
    $!meta-data<type> = $type;
    $!meta-data<exists> = $object.IO ~~ :r;
    $!meta-data<content-sha1> = self!sha1-content($object);

    self!add-meta;
    info-message("metadata set for $object");
  }

  #-----------------------------------------------------------------------------
  method update-meta ( --> BSON::Document ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the file what to do.
    my BSON::Document $doc;

#    if $!meta-data<exists> {
#      # Drop user data from this object to prevent overwriting
#      # existing user provided data
#      $!meta-data<user-data>:delete;

      # If file is found, we do not have to do anything
      # So if not found ...
      if self!find-in-db: (
        name => $!meta-data<name>,
        path => $!meta-data<path>,
        type => OT-File,
        content-sha1 => $!meta-data<content-sha1>,
        hostname => $!meta-data<hostname>,
      ) {

        debug-message("$!meta-data<name> found by name, path and content, no update");
      }

      else {

        debug-message("$!meta-data<name> not found by name, path, content");

        # File maybe moved
        if self!find-in-db: (
            name => $!meta-data<name>,
            type => OT-File,
            content-sha1 => $!meta-data<content-sha1>,
            hostname => $!meta-data<hostname>,
        ) {

          info-message("$!meta-data<name> found -> must be moved, updated");

          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => (
                name => $!meta-data<name>,
                type => OT-File,
                content-sha1 => $!meta-data<content-sha1>,
                hostname => $!meta-data<hostname>,
              ),
              u => ( '$set' => $!meta-data,),
            ),
          ];
        }

        # File may be renamed
        elsif self!find-in-db: (
            type => OT-File,
            path => $!meta-data<path>,
            content-sha1 => $!meta-data<content-sha1>,
            hostname => $!meta-data<hostname>,
        ) {

          info-message("$!meta-data<name> found -> must be renamed, updated");

          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => (
                type => OT-File,
                path => $!meta-data<path>,
                content-sha1 => $!meta-data<content-sha1>,
                hostname => $!meta-data<hostname>,
              ),
              u => ( '$set' => $!meta-data,),
            ),
          ];
        }

        # File may be moved and renamed
        elsif self!find-in-db: (
            type => OT-File,
            content-sha1 => $!meta-data<content-sha1>,
            hostname => $!meta-data<hostname>,
        ) {

          info-message("$!meta-data<name> found -> must be renamed and moved, updated");

          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => (
                type => OT-File,
                content-sha1 => $!meta-data<content-sha1>,
                hostname => $!meta-data<hostname>,
              ),
              u => ( '$set' => $!meta-data,),
            ),
          ];
        }

        # File may be modified
        elsif self!find-in-db: (
            name => $!meta-data<name>,
            type => OT-File,
            path => $!meta-data<path>,
            hostname => $!meta-data<hostname>,
        ) {

          info-message("$!meta-data<name> found -> must be modified or deleted, updated");

          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => (
                name => $!meta-data<name>,
                type => OT-File,
                path => $!meta-data<path>,
                hostname => $!meta-data<hostname>,
              ),
              u => ( '$set' => $!meta-data,),
            ),
          ];
        }

        # different file
        else {

          info-message("$!meta-data<name> not found -> must be new, updated");

          $doc = $!dbo.insert: [$!meta-data];
        }
      }
#    }

    $doc;
  }
}
