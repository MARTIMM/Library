use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Metadata::Database;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
role Metadata::Object {

  has BSON::Document $!meta-data;
  has Library::Metadata::Database $!dbo handles <
    insert update delete count find drop-collection drop-database
  >;

  has Array $!filter-list;

  #----------------------------------------------------------------------------
  method specific-init-meta ( Str :$object ) { ... }
  method update-meta ( ) { ... }

  #----------------------------------------------------------------------------
  submethod BUILD ( Str :$object ) {

    $!filter-list = [<
      the they their also are all and him his her hers mine our mine our ours was
      following some various see most much many about you yours none
    >];

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

    $!meta-data<user-meta> // BSON::Document.new
  }

  #----------------------------------------------------------------------------
  method set-user-metadata (
    $data where (? $_ and $_ ~~ any(List|BSON::Document))
    --> BSON::Document
  ) {

    # modify user metadata and update document
    $!meta-data<user-meta> = $data;
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

        u => ( '$set' => ( user-meta => $!meta-data<user-meta>,),),
        upsert => False,
      ),
    ]
  }

  #----------------------------------------------------------------------------
  # update tags stored in the field 'tags' of a meta data subdocument. The
  # subdocument is by default 'user-meta'.
  method set-metadata-tags (
    Str:D $object-name, Bool :$et = False, Str :$subdoc = 'user-meta',
    Array :$arg-tags = [], Array :$drop-tags = [],
  ) {

    my Array $tags = [];

    # get user meta data
    my BSON::Document $udata = $object.get-user-metadata;
    my Array $prev-tags = $udata<tags> // [];

    # check if to extract tags from object name
    if $et {
      $tags = [
        $arg-tags.Slip,
        $object-name.split(/ [\s || <punct> || \d]+ /).List.Slip,
        $prev-tags.Slip
      ];
    }

    else {
      $tags = [ $arg-tags.Slip, $prev-tags.Slip];
    }

    # Filter tags shorter than 3 chars, lowercase convert, remove
    # doubles then sort
    $tags = [$tags.grep(/^...+/)>>.lc.unique.sort.List.Slip];

note "FL: ", $filter-list, $drop-tags;
    # remove any tags
    for |@$!filter-list, |@$drop-tags -> $t is copy {
      $t .= lc;
      if (my $index = $tags.first( $t, :k)).defined {
note "Filter $t: $index";
        $tags.splice( $index, 1);
      }
    }

note "TL: ", $tags;

    # save new set of tags
    $udata<tags> = $tags;
    $object.set-user-metadata($udata);
  }

  #----------------------------------------------------------------------------
  method !sha1-content ( Str $object --> Str ) {

    return '' unless $object.IO !~~ :d and $object.IO ~~ :r;

    my Str $sha-content = '';

    my Proc $p = run 'sha1sum', $object, :out;
    $sha-content = [~] $p.out.lines;
    $sha-content ~~ s/ \s+ .* $//;

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
