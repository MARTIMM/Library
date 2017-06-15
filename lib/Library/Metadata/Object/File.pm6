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
  method specific-init-meta ( Str :$object, ObjectType :$type ) {

    my Str $path = $object.IO.absolute;
    my Str $file = $object.IO.basename;
    my Str $extension = $object.IO.extension;
    $path ~~ s/ '/'? $file $//;

    $!meta-data<name> = $file;
    $!meta-data<extension> = $extension;
    $!meta-data<path> = $path;
    $!meta-data<type> = $type.Str;
    $!meta-data<exists> = $object.IO ~~ :r;
    $!meta-data<content-sha1> = self!sha1-content($object);

    self!add-meta;
    info-message("metadata set for $object");
note "MD: $!meta-data.gist()";
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
      type => ~OT-File,
      content-sha1 => $!meta-data<content-sha1>,
      hostname => $!meta-data<hostname>,
    ) {
note "Found: name, type, path, sha, hname";

      info-message("File $!meta-data<name> found by name, path and content, no update");
    }

    # So if not found ...
    else {

      info-message("File $!meta-data<name> not found by name, path, content");

#`{{
      # File maybe moved
      $query .= new: (
          name => $!meta-data<name>,
          type => ~OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      );
}}
      if self.find-in-db( (
          name => $!meta-data<name>,
          type => ~OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
        )
      ) {

        # Check first if file from this search has an existing file
        # if so, do not modify the record.
        my Bool $exists = False;
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = self.update: [ (
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
      elsif self.find-in-db( (
          type => ~OT-File,
          path => $!meta-data<path>,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      )) {
note "Found: type, path, sha, hname";

        # Check first if file from this search has an existing file
        my Bool $exists = False;
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = self.update: [ (
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
      elsif self.find-in-db( (
          type => ~OT-File,
          content-sha1 => $!meta-data<content-sha1>,
          hostname => $!meta-data<hostname>,
      )) {
note "Found: type, sha, hname";

        # Check first if file from this search has an existing file
        my Bool $exists = False;
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = self.update: [ (
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
      elsif self.find-in-db( (
          name => $!meta-data<name>,
          type => ~OT-File,
          path => $!meta-data<path>,
          hostname => $!meta-data<hostname>,
      )) {
note "Found: name, type, path, hname";

        # Check first if file from this search has an existing file
        my Bool $exists = False;
        for self.find(:criteria($query)) -> $d {
          if "$d<path>/$d<name>".IO ~~ :e {
            $exists = True;
            last;
          }
        }

        unless $exists {
          # Update the record to reflect current situation
          $doc = self.update: [ (
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
note "Not found: new insert";

        info-message("$!meta-data<name> not found -> must be new, updated");

        $doc = self.insert: [$!meta-data];
      }
    }

    $doc;
  }
}
