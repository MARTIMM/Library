use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Config::SkipList;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
class Metadata::Object::Directory does Library::Metadata::Object {

  #----------------------------------------------------------------------------
  # Set the default informaton for a directory in the meta structure
  method specific-init-meta ( --> Bool ) {

    my Str $path = $!object.IO.absolute;
    my Str $dir = $!object.IO.basename;
    $path ~~ s/ '/'? $dir $//;

    $!meta-data<name> = $dir;
    $!meta-data<path> = $path;
    $!meta-data<meta-type> = OT-Directory.Str;
    $!meta-data<exists> = $!object.IO ~~ :r;

    return True;
  }

  #----------------------------------------------------------------------------
  # Update database with the data in the meta structure.
  # Returns result document with at least key field 'ok'
  method update-meta ( --> BSON::Document ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the directory what to do.
    my BSON::Document $doc .= new: (:ok(1));
    my BSON::Document $query;

    # If file is found in db, we do not have to do anything
    if self.is-in-db: (
      name => $!meta-data<name>,
      path => $!meta-data<path>,
      meta-type => OT-Directory,
      hostname => $!meta-data<hostname>,
    ) {

      info-message("directory $!meta-data<name> found by name and path, no update");
    }

    # So if not found ...
    else {

      info-message("directory $!meta-data<name> not found by name and path -> must be new, inserted");
      $doc = self.insert: [$!meta-data];

      # No complex search like in ::File because the info tuple is larger.
    }

    # return database operations result
    $doc
  }
}
