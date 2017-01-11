use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;

use OpenSSL::Digest;
use BSON::Document;

#-------------------------------------------------------------------------------
class Metadata::Object::File {

  has BSON::Document $!d;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$object, ObjectType :$type ) {

    $!d .= new;

    my Str $path = $object.IO.abspath;
    my Str $file = $object.IO.basename;
    $path ~~ s/ '/'? $file //;

    my Proc $p;
    my @lines = ();
    if $object.IO ~~ :r {
      $p = run 'sha1sum', $object, :out;
      @lines = $p.out.lines;
    }

    $!d<object-name> = $file;
    $!d<object-path> = $path;
    $!d<object-type> = $type;
    $!d<object-exists> = $object.IO ~~ :r;

    $!d<file-sha1> = self!sha1($file);
    $!d<path-sha1> = self!sha1($path);
    $!d<content-sha1> = [~] @lines;
  }

  #-----------------------------------------------------------------------------
  method meta ( ) {

    $!d;
  }
  
  #-----------------------------------------------------------------------------
  method !sha1 ( Str $s --> Str ) {
    (sha1( $s.encode)>>.fmt('%02x')).join('');
  }
}
