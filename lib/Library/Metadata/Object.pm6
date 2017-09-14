use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Database;
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
  method set-tag-filter ( @filter-list ) {

    # use role as a class. initialize with database and collection
    my Library::Database $d .= new;
    $d.init( :database-key<database>, :collection-key<meta-config>);

    # find the config doc
    my $c = $d.find( BSON::Document.new(
       :criteria(:config-type<tag-filter>,),
        :number-to-return(1)
      )
    );

    my BSON::Document $doc;
    if ?$c {
      $doc = $c.fetch;
    }

    # init if there isn't a document
    $doc //= BSON::Document.new;

    my Array $array = [(($doc<tags> // []).Slip, |@filter-list).unique];
    $doc = $d.update: [ (
        q => (
          :config-type<tag-filter>,
        ),

        u => ( '$set' => ( :tags($array),),),
        upsert => False,
      ),
    ];
  }

  #----------------------------------------------------------------------------
  method get-metameta ( Str :$subdoc = 'user-meta' --> BSON::Document ) {

    $!meta-data{$subdoc} // BSON::Document.new
  }

  #----------------------------------------------------------------------------
  method set-metameta (
    $data where (? $_ and $_ ~~ any(List|BSON::Document)),
    Str :$subdoc = 'user-meta'
    --> BSON::Document
  ) {

    # modify user metadata and update document
    $!meta-data{$subdoc} = $data;
    self!update-metameta(:$subdoc)
  }

  #----------------------------------------------------------------------------
  # update fields of a meta data subdocument. The subdocument is by default
  # at meta field 'user-meta'.
  method !update-metameta ( Str :$subdoc = 'user-meta' --> BSON::Document ) {

    # store in database only if record is found
    my BSON::Document $doc = $!dbo.update: [ (
        q => (
          name => $!meta-data<name>,
          path => $!meta-data<path>,
#          content-sha1 => $!meta-data<content-sha1>,
        ),

        u => ( '$set' => ( $subdoc => $!meta-data{$subdoc},),),
        upsert => False,
      ),
    ];

    if $doc<ok> {
      my $selected = $doc<n>;
      my $modified = $doc<nModified>;
      info-message("metameta $subdoc update: selected = $selected, modified = $modified");
    }

    else {
      if $doc<writeErrors> {
        for $doc<writeErrors> -> $we {
          warn-message("metameta $subdoc update: " ~ $we<errmsg>);
        }
      }

      elsif $doc<errmsg> {
        warn-message("metameta $subdoc update: ", $doc<errmsg>);
      }

      else {
        warn-message("metameta $subdoc update: unknown error");
      }
    }

    $doc
  }

  #----------------------------------------------------------------------------
  # update tags stored in the field 'tags' of a meta data subdocument. The
  # subdocument is by default 'user-meta'.
  method set-metameta-tags (
    Str:D $object, Bool :$et = False, Str :$subdoc = 'user-meta',
    Array :$arg-tags = [], Array :$drop-tags = [],
  ) {

    my Array $tags = [];

    # get user meta data
    my BSON::Document $udata = self.get-metameta(:$subdoc);
    my Array $prev-tags = $udata<tags> // [];

    # check if to extract tags from object name
    if $et {
      $tags = [
        $arg-tags.Slip,
        $object.split(/ [\s || <punct> || \d]+ /).List.Slip,
        $prev-tags.Slip
      ];
    }

    else {
      $tags = [ $arg-tags.Slip, $prev-tags.Slip];
    }

    # Filter tags shorter than 3 chars, lowercase convert, remove
    # doubles then sort
    $tags = [$tags.grep(/^...+/)>>.lc.unique.sort.List.Slip];

note "FL: ", $!filter-list, $drop-tags;
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
    self.set-metameta( $udata, :$subdoc);
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
