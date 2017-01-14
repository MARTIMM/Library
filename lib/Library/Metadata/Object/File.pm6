use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Object;

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

    my Str $sha-content = self!sha1-content($object);

    $!meta-data<name> = $file;
    $!meta-data<extension> = $extension;
    $!meta-data<path> = $path;
    $!meta-data<type> = $type;
    $!meta-data<exists> = $object.IO ~~ :r;

    $!meta-data<file-sha1> = self!sha1($file);
    $!meta-data<path-sha1> = self!sha1($path);
    $!meta-data<content-sha1> = $sha-content if ?$sha-content;

    $!meta-data<user-data> = ( keys => [], );
    $!meta-data<user-data> = ( note => '', );
  }

  #-----------------------------------------------------------------------------
  method update-meta ( ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the file what to do.
    #
    my BSON::Document $doc;
    if $!meta-data<exists> {

      # Check if it is moved from somewhere or renamed
      # If moved it should be findable by file sha1

      my Bool $by-file-sha = ? (
        $!dbo.count: (
          file-sha1 => $!meta-data<file-sha1>,
        )
      )<n>;

say "Found by name: ", $by-file-sha;

      # If renamed it should be findable by path sha1 but there are more files
      # in the same directory!
      my Bool $by-path-sha = ? ($!dbo.count: ( name => $!meta-data<name>,))<n>;

      $doc = $!dbo.insert: [$!meta-data] unless $by-file-sha;
say "insert: ", $doc.perl unless $by-file-sha;
    }

    # Object does not exist. Try to find it using the metadata
    else {

    }

#search ?? insert !! update
#    self.update([$!meta-object.meta,]);
  }
}
