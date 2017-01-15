use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;

use OpenSSL::Digest;
use BSON::Document;

#-------------------------------------------------------------------------------
role Metadata::Object {

  has BSON::Document $!meta-data;
  has $!dbo where .^name ~~ 'Library::Metadata::Database';

  #-----------------------------------------------------------------------------
  method init-meta ( Str :$object, ObjectType :$type ) { ... }
  method update-meta ( ) { ... }

  #-----------------------------------------------------------------------------
  submethod BUILD ( :$dbo, Str :$object, ObjectType :$type ) {

    $!dbo = $dbo;
    $!meta-data .= new;

    self.init-meta( :$object, :$type);
  }

  #-----------------------------------------------------------------------------
  method meta ( --> BSON::Document ) {

    $!meta-data;
  }

  #-----------------------------------------------------------------------------
  method get-user-metadata ( --> BSON::Document ) {

    $!meta-data<user-data> // BSON::Document.new;
  }

  #-----------------------------------------------------------------------------
  multi method set-user-metadata ( List:D $data --> BSON::Document ) {

    # modify user metadata and update document
    $!meta-data<user-data> = $data;
    self!update-usermeta;
  }

  multi method set-user-metadata ( BSON::Document:D $data --> BSON::Document ) {

    # modify user metadata and update document
    $!meta-data<user-data> = $data;
    self!update-usermeta;
  }

  #-----------------------------------------------------------------------------
  method !update-usermeta ( --> BSON::Document ) {

    # store in database only if record is found
    $!dbo.update: [ (
        q => (
          name => $!meta-data<name>,
          path => $!meta-data<path>,
          content-sha1 => $!meta-data<content-sha1>,
        ),

        u => ( '$set' => ( user-data => $!meta-data<user-data>,),),
        upsert => False,
      ),
    ];
  }

  #-----------------------------------------------------------------------------
  method !sha1 ( Str $s --> Str ) {

    (sha1( $s.encode)>>.fmt('%02x')).join('');
  }

  #-----------------------------------------------------------------------------
  method !sha1-content ( Str $object --> Str ) {

    return '' unless $object.IO !~~ :d and $object.IO ~~ :r;

    my Str $sha-content = '';

    # If larger than 10 Mb do not suck it up but let another program work on it
    if $object.IO.s > 10_485_760 {

      my Proc $p;
      if $object.IO ~~ :r {
        $p = run 'sha1sum', $object, :out;
        $sha-content = [~] $p.out.lines;
        $sha-content ~~ s/ \s+ .* $//;
      }
    }

    else {

      $sha-content = (sha1(slurp($object).encode)>>.fmt('%02x')).join('');
    }

    $sha-content;
  }

  #-----------------------------------------------------------------------------
  method !find-in-db ( List:D $query --> Bool ) {

    ? ( $!dbo.count: ( $query ) )<n>;
  }

  #-----------------------------------------------------------------------------
  method !add-meta ( ) {

    $!meta-data<hostname> = qx[hostname];
  }
}
