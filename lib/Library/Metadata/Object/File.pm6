use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

use BSON::Document;

#-------------------------------------------------------------------------------
class Metadata::Object::File does Library::Metadata::Object {

  #-----------------------------------------------------------------------------
  submethod init-meta ( Str :$object, ObjectType :$type ) {

    my Str $path = $object.IO.abspath;
    my Str $file = $object.IO.basename;
    my Str $extension = $object.IO.extension;
    $path ~~ s/ '/'? $file $//;

    my Str $sha-content = self!sha1-content($object);

    $!meta-data<name> = $file;
    $!meta-data<extension> = $extension;
    $!meta-data<path> = $path;
    $!meta-data<type> = $type;
    $!meta-data<exists> = $object.IO ~~ :r;

    $!meta-data<file-sha1> = self!sha1($file);
    $!meta-data<path-sha1> = self!sha1($path);
    $!meta-data<content-sha1> = $sha-content if ?$sha-content;
  }

  #-----------------------------------------------------------------------------
  method update-meta ( ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the file what to do.
    #
    my BSON::Document $doc;
    if $!meta-data<exists> {

      $doc = $!dbo.count: ( name => $!meta-data<name>,);
      $!dbo.insert: [$!meta-data] unless $doc<n>;
say $doc;
    }
    
    # Object does not exist. Try to find it using the 
    else {
    
      
    }

#search ?? insert !! update
#    self.update([$!meta-object.meta,]);
  }
}
