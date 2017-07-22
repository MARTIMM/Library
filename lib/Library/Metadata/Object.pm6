use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Database;

use OpenSSL::Digest;
use BSON::Document;

#-------------------------------------------------------------------------------
role Metadata::Object {

  has BSON::Document $!meta-data;
  has Library::Metadata::Database $!dbo handles <
    insert update delete count find drop-collection drop-database
  >;

  #-----------------------------------------------------------------------------
  #method init-meta ( Str :$object, ObjectType :$type ) { ... }
  #method update-meta ( ) { ... }

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!meta-data .= new;
    $!dbo .= new;
  }

  #-----------------------------------------------------------------------------
  method meta ( --> BSON::Document ) {

    $!meta-data;
  }

  #-----------------------------------------------------------------------------
  method init-meta(
    Str :$object, ObjectType :$type
    --> Library::Metadata::Object
  ) {

    # create object of this classes child and generate metadata
    # with the arguments provided by the child
    my $class-type = "Library::Metadata::Object::$type";
    require ::($class-type);
    my $meta-object = ::($class-type).new( :$object, :$type);
note "XO: ", $meta-object.perl;

    # modify database if needed
    $meta-object.specific-init-meta( :$object, :$type);
    my $doc = $meta-object.update-meta;
note "L::M::D: ", $doc.perl;

    $meta-object;
  }

  #-----------------------------------------------------------------------------
  method get-user-metadata ( --> BSON::Document ) {

    $!meta-data<user-data> // BSON::Document.new;
  }

  #-----------------------------------------------------------------------------
  method set-user-metadata (
    $data where (? $_ and $_ ~~ any(List|BSON::Document))
    --> BSON::Document
  ) {

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
  multi method find-in-db ( List:D $query --> Bool ) {

    # use n to see the number of found records 0 coerces to False, True otherwise
    ? ( $!dbo.count: ( $query ) )<n>;
  }

  multi method find-in-db ( BSON::Document:D $query --> Bool ) {

    my BSON::Document $r = $!dbo.count: ( $query );
    ? ($r<ok> and $r<n>);
  }

  #-----------------------------------------------------------------------------
  method !add-meta ( ) {

    $!meta-data<hostname> = qx[hostname].chomp;
  }
}
