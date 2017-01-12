use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use OpenSSL::Digest;
use BSON::Document;

#-------------------------------------------------------------------------------
role Metadata::Object {

  has BSON::Document $!meta-data;

  #-----------------------------------------------------------------------------
  method meta ( ) {

    $!meta-data;
  }
  
  #-----------------------------------------------------------------------------
  method !sha1 ( Str $s --> Str ) {

    (sha1( $s.encode)>>.fmt('%02x')).join('');
  }
  
  #-----------------------------------------------------------------------------
  method !sha1-content ( Str $object --> Str ) {

    my Proc $p;
    my Str $sha-content = '';
    if $object.IO ~~ :r {
      $p = run 'sha1sum', $object, :out;
      $sha-content = [~] $p.out.lines;
      $sha-content ~~ s/ \s+ .* $//;
    }

    $sha-content;
  }
}
