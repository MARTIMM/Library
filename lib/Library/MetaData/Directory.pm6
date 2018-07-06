use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
#use Library::MetaConfig::SkipDataList;
use Library::MetaData;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
class MetaData::Directory does Library::MetaData {

  #-----------------------------------------------------------------------------
  # Set the default information for a directory in the meta structure
  method specific-init-meta ( --> Bool ) {

    my Str $path = $!object.IO.absolute;
    my Str $dir = $!object.IO.basename;
    $path ~~ s/ '/'? $dir $//;

    my BSON::Document $object-meta .= new;
    $object-meta<meta-type> = MT-Directory.Str;
    $object-meta<path> = $path;
    $object-meta<exists> = $!object.IO ~~ :r;
    $object-meta<hostname> = qx[hostname].chomp;

    $!meta-data<name> = $dir;
    $!meta-data<object-meta> = $object-meta;

    return True;
  }

  #-----------------------------------------------------------------------------
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
      object-meta => (path => $!meta-data<path>,),
      object-meta => (meta-type => MT-Directory,),
      object-meta => (hostname => $!meta-data<hostname>,),
    ) {

      info-message(
        "directory $!meta-data<name> found by name and path, no update"
      );
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
