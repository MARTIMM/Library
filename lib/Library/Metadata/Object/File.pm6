use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

#-------------------------------------------------------------------------------
class Metadata::Object::File does Library::Metadata::Object {

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$object, ObjectType :$type ) {

    $!meta-data .= new;

    my Str $path = $object.IO.abspath;
    my Str $file = $object.IO.basename;
    my Str $extension = $object.IO.extension;
    $path ~~ s/ '/'? $file $//;

    my Str $sha-content = self!sha1-content($object);

    $!meta-data<object-name> = $file;
    $!meta-data<object-extension> = $extension;
    $!meta-data<object-path> = $path;
    $!meta-data<object-type> = $type;
    $!meta-data<object-exists> = $object.IO ~~ :r;

    $!meta-data<file-sha1> = self!sha1($file);
    $!meta-data<path-sha1> = self!sha1($path);
    $!meta-data<content-sha1> = $sha-content if ?$sha-content;
  }
}
