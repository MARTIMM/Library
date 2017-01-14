use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

#-------------------------------------------------------------------------------
class Metadata::Object::Directory does Library::Metadata::Object {

  #-----------------------------------------------------------------------------
  # $!metadata and $!dbo are defined in Library::Metadata::Object and
  # initialized in BUILD. BUILD calls init-meta to generated the metadata.
  method init-meta ( Str :$object, ObjectType :$type ) {

    my Str $path = $object.IO.abspath;
    my Str $dir = $object.IO.basename;
    $path ~~ s/ '/'? $dir $//;

    $!meta-data<name> = $dir;
    $!meta-data<path> = $path;
    $!meta-data<type> = $type;
    $!meta-data<exists> = $object.IO ~~ :r;

    $!meta-data<directory-sha1> = self!sha1($dir);
    $!meta-data<path-sha1> = self!sha1($path);

    self!add-meta;
  }

  #-----------------------------------------------------------------------------
  method update-meta ( ) {

  }
}
