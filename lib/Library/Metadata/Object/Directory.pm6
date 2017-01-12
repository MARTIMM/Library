use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

#-------------------------------------------------------------------------------
class Metadata::Object::Directory does Library::Metadata::Object {

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$object, ObjectType :$type ) {

    $!meta-data .= new;

    my Str $path = $object.IO.abspath;
    my Str $dir = $object.IO.basename;
    $path ~~ s/ '/'? $dir $//;

    $!meta-data<object-name> = $dir;
    $!meta-data<object-path> = $path;
    $!meta-data<object-type> = $type;
    $!meta-data<object-exists> = $object.IO ~~ :r;

    $!meta-data<directory-sha1> = self!sha1($dir);
    $!meta-data<path-sha1> = self!sha1($path);
  }
}
