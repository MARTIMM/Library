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
    my Str $dir = $path.IO.basename;

    # Drop top directory from path
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

    # If file is found in db, we do not have to do anything.
    # keep in same order as stored!
    my BSON::Document $object-meta = $!meta-data<object-meta>;
    if self.is-in-db: (
      name => $!meta-data<name>,
      "object-meta.meta-type" => MT-Directory,
      "object-meta.path" => $object-meta<path>,
      "object-meta.hostname" => $object-meta<hostname>,
      ) {

      # Update the record to modify any other non-tested but changed fields
      $doc = self.update: [ (
          q => $query,
          u => ( '$set' => $!meta-data,),
        ),
      ];

      self!log-update-message($doc);
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
