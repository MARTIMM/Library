use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Storage;
use Library::Config::TagsList;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
role Metadata::Object {

  has BSON::Document $!meta-data;
  has Library::Storage $!dbo handles <
        insert update delete count find drop-collection drop-database
      >;

  has Array $!filter-list;

  # ignore the object when an object is filtered out
  has Bool $!ignore-object;

  has Str $!object;

  #-----------------------------------------------------------------------------
  method specific-init-meta ( --> Bool ) { ... }
  method update-meta ( ) { ... }

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( IO::Path:D :$object ) {

    fatal-message('empty path objects are not handled') unless
      $object.Str.chars > 0;

    $!object = $object.Str;
    self!take-object;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD ( Str:D :$object ) {
    fatal-message('empty path objects are not handled') unless
      $object.chars > 0;

    $!object = $object;
    self!take-object;
  }

  #-----------------------------------------------------------------------------
  method meta ( --> BSON::Document ) {

    $!meta-data
  }

  #-----------------------------------------------------------------------------
  method get-metameta ( Str :$subdoc = 'user-meta' --> BSON::Document ) {

    $!meta-data{$subdoc} // BSON::Document.new
  }

  #-----------------------------------------------------------------------------
  method set-metameta (
    $data where (? $_ and $_ ~~ any(List|BSON::Document)),
    Str :$subdoc = 'user-meta'
    --> BSON::Document
  ) {

    my BSON::Document $doc .= new;

    unless $!ignore-object {
      # modify user metadata and update document
      $!meta-data{$subdoc} = $data;
      $doc = self!update-metameta(:$subdoc);
    }

    $doc
  }

  #-----------------------------------------------------------------------------
  # update tags stored in the field 'tags' of a meta data subdocument. The
  # subdocument is by default 'user-meta'.
  method set-metameta-tags (
    Bool :$extract-tags = False, Str :$subdoc = 'user-meta',
    Array :$arg-tags = [], Array :$drop-tags is copy = [],
  ) {

    return BSON::Document.new if $!ignore-object;

    my Library::Config::TagsList $ct .= new;
    my Array $tags = [];

    # get user meta data
    my BSON::Document $udata = self.get-metameta(:$subdoc);
    my Array $prev-tags = $udata<tags> // [];

    # filter out type tags
    my Str $e = $!object.IO.extension;
    $drop-tags.push($e) if ?$e;

    # check if to extract tags from object name
    if $extract-tags {
      $tags = $ct.filter-tags( [
          $arg-tags.Slip,
          $!object.split(/ [\s || <punct>]+ /).List.Slip,
          $prev-tags.Slip
        ],
        $drop-tags
      );
    }

    else {
      $tags = $ct.filter-tags(
        [ $arg-tags.Slip, $prev-tags.Slip],
        $drop-tags
      );
    }

    # save new set of tags
note "T: ", $tags;
note "S: ", $subdoc.perl;
    $udata<tags> = $tags;
    self.set-metameta( $udata, :$subdoc);
  }

  #-----------------------------------------------------------------------------
  multi method is-in-db ( List:D $query --> Bool ) {

    # use n to see the number of found records. 0 coerces to False, True otherwise
    ? ( $!dbo.count: ( $query ) )<n>
  }

  multi method is-in-db ( BSON::Document:D $query --> Bool ) {

    # use n to see the number of found records. 0 coerces to False, True otherwise
    ? ( $!dbo.count: ( $query ) )<n>
  }

  # ==[ Private stuff ]=========================================================
  #-----------------------------------------------------------------------------
  # update fields of a meta data subdocument. The subdocument is by default
  # at meta field 'user-meta'.
  method !update-metameta (
    Str :$subdoc = 'user-meta'
    --> BSON::Document
  ) {

    return BSON::Document.new if $!ignore-object;

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

  #-----------------------------------------------------------------------------
  method !sha1-content ( Str $object --> Str ) {

    return '' unless $object.IO !~~ :d and $object.IO ~~ :r;

    my Str $sha-content = '';

    my Proc $p = run 'sha1sum', $object, :out;
    $sha-content = [~] $p.out.lines;
    $sha-content ~~ s/ \s+ .* $//;

    $sha-content
  }

  #-----------------------------------------------------------------------------
  method !take-object( ) {
    $!ignore-object = False;

    my Library::Config::TagsList $c .= new(:root);
    $!filter-list = $c.get-tag-filter;

    # always select the meta-data collection in users database
    $!dbo .= new(:collection-key<meta-data>);
    self!init-meta;
  }

  #-----------------------------------------------------------------------------
  method !init-meta ( --> BSON::Document ) {

    my BSON::Document $doc .= new;

    # modify database if needed
    $!meta-data .= new;
    if self.specific-init-meta {
      $doc = self.update-meta;
    }

    else {
      $!ignore-object = True;
    }

    $doc
  }

  #-----------------------------------------------------------------------------
  method !log-update-message ( BSON::Document:D $doc ) {

    if $doc<ok> == 1 {
      info-message("meta data of $!meta-data<name> updated");
    }

    else {
      error-message("updating meta data of $!meta-data<name> failed, err: $doc<errmsg>");
    }
  }
}
