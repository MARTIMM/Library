use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Database;

use OpenSSL::Digest;
use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
role Metadata::Object {

  has BSON::Document $!meta-data;
  has Library::Metadata::Database $!dbo handles <
    insert update delete count find drop-collection drop-database
  >;

  #----------------------------------------------------------------------------
  method specific-init-meta ( Str :$object ) { ... }
  method update-meta ( ) { ... }

  #----------------------------------------------------------------------------
  submethod BUILD ( Str :$object ) {

    $!dbo .= new;
    if ?$object {
      self.init-meta(:$object);
    }

    else {
      $!meta-data .= new;
    }
  }

  #----------------------------------------------------------------------------
  method init-meta ( Str :$object --> BSON::Document ) {

    # modify database if needed
    $!meta-data .= new;
    self.specific-init-meta(:$object);
    self!add-global-meta;
    self.update-meta
  }

  #----------------------------------------------------------------------------
  method meta ( --> BSON::Document ) {

    $!meta-data
  }

  #----------------------------------------------------------------------------
  method get-user-metadata ( --> BSON::Document ) {

    $!meta-data<user-data> // BSON::Document.new
  }

  #----------------------------------------------------------------------------
  method set-user-metadata (
    $data where (? $_ and $_ ~~ any(List|BSON::Document))
    --> BSON::Document
  ) {

    # modify user metadata and update document
    $!meta-data<user-data> = $data;
    self!update-usermeta
  }

  #----------------------------------------------------------------------------
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
    ]
  }

  #----------------------------------------------------------------------------
  method !sha1 ( Str $s --> Str ) {

    (sha1( $s.encode)>>.fmt('%02x')).join('')
  }

  #----------------------------------------------------------------------------
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

    $sha-content
  }

  #----------------------------------------------------------------------------
  multi method is-in-db ( List:D $query --> Bool ) {

    # use n to see the number of found records. 0 coerces to False, True otherwise
    ? ( $!dbo.count: ( $query ) )<n>
  }

  multi method is-in-db ( BSON::Document:D $query --> Bool ) {

    # use n to see the number of found records. 0 coerces to False, True otherwise
    ? ( $!dbo.count: ( $query ) )<n>
  }

  #----------------------------------------------------------------------------
  # Add global defaults to the meta structure
  method !add-global-meta ( ) {

    $!meta-data<hostname> = qx[hostname].chomp;
  }

  #----------------------------------------------------------------------------
  method !log-update-message ( BSON::Document:D $doc ) {

    if $doc<ok> == 1 {
      info-message("meta data of $!meta-data<name> updated");
    }

    else {
      error-message("updating meta data of $!meta-data<name> failed, err: $doc<errmsg>");
    }
  }
}
