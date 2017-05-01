use v6;

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

    my Str $path = $object.IO.absolute;
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
    my BSON::Document $doc .= new: (:ok(1));
    my BSON::Document $query;

    # If file is found in db, we do not have to do anything
    if self.find-in-db: (
      name => $!meta-data<name>,
      path => $!meta-data<path>,
      type => OT-File,
      content-sha1 => $!meta-data<content-sha1>,
      hostname => $!meta-data<hostname>,
    ) {

      debug-message("$!meta-data<name> found by name, path and content, no update");
    }

    # So if not found ...
    else {

      debug-message("$!meta-data<name> not found by name, path, content");

      # File maybe moved
      $query .= new: (
          name => $!meta-data<name>,
          type => OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      );

      if self.find-in-db($query) {

        # Check first if file from this search has an existing file
        # if so, do not modify the record.
        my Bool $exists = False;
        for $!dbo.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => $query,
              u => ( '$set' => $!meta-data,),
            ),
          ];

          if $doc<ok> == 1 {
            info-message("$!meta-data<name> found -> must be moved, updated");
          }

          else {
            error-message("updating $!meta-data<name> failed, err: $doc<errmsg>\($doc<code>\)");
          }
        }
      }

      # File may be renamed
      elsif self.find-in-db($query .= new: (
          type => OT-File,
          path => $!meta-data<path>,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      )) {

        # Check first if file from this search has an existing file
        my Bool $exists = False;
        for $!dbo.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => $query,
              u => ( '$set' => $!meta-data,),
            ),
          ];

          if $doc<ok> == 1 {
            info-message("$!meta-data<name> found -> must be renamed, updated");
          }

          else {
            error-message("updating $!meta-data<name> failed, err: $doc<errmsg>\($doc<code>\)");
          }
        }
      }

      # File may be moved and renamed
      elsif self.find-in-db($query .= new: (
          type => OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      )) {

        # Check first if file from this search has an existing file
        my Bool $exists = False;
        for $!dbo.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => $query,
              u => ( '$set' => $!meta-data,),
            ),
          ];

          if $doc<ok> == 1 {
            info-message("$!meta-data<name> found -> must be renamed and moved, updated");
          }

          else {
            error-message("updating $!meta-data<name> failed, err: $doc<errmsg>\($doc<code>\)");
          }
        }
      }

      # File may be modified
      elsif self.find-in-db($query .= new: (
          name => $!meta-data<name>,
          type => OT-File,
          path => $!meta-data<path>,
          hostname => $!meta-data<hostname>,
      )) {

        # Check first if file from this search has an existing file
        my Bool $exists = False;
        for $!dbo.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = $!dbo.update: [ (
              q => $query,
              u => ( '$set' => $!meta-data,),
            ),
          ];

          if $doc<ok> == 1 {
            info-message("$!meta-data<name> found -> must be modified or deleted, updated");
          }

          else {
            error-message("updating $!meta-data<name> failed, err: $doc<errmsg>\($doc<code>\)");
          }
        }
      }

      # different file
      else {

        info-message("$!meta-data<name> not found -> must be new, updated");

        $doc = $!dbo.insert: [$!meta-data];
      }
    }

    $doc;
  }
}
