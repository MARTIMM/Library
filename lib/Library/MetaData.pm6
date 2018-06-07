use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Storage;
use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
role MetaData {

  has BSON::Document $!meta-data;
  has Library::Storage $!dbo handles <
        insert update delete count find drop-collection drop-database
      >;

  # ignore the object when an object is filtered out
  has Bool $.ignore-object;

  has Str $!object;
  has Array $!tags-filter;

  #-----------------------------------------------------------------------------
  method specific-init-meta ( --> Bool ) { ... }
  method update-meta ( ) { ... }

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( IO::Path:D :$object ) {

    fatal-message('empty path objects are not handled') unless
      $object.Str.chars > 0;

    $!object = $object.Str;
    self!process-object;
  }

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi submethod BUILD ( Str:D :$object ) {
    fatal-message('empty path objects are not handled') unless
      $object.chars > 0;

    $!object = $object;
    self!process-object;
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
  method set-metameta-tags ( Str :$subdoc = 'user-meta' ) {

    return if $!ignore-object;

    my Library::MetaConfig::TagFilterList $ct .= new;

    # get user meta data
    my BSON::Document $udata = self.get-metameta(:$subdoc);
    my Array $prev-tags = $udata<tags> // [];
note $udata.perl;

    # filter out type tags
#    my Str $e = $!object.IO.extension;
#    $drop-tags.push($e) if ?$e;

    # check if to extract tags from object name
    my Array $tags = $ct.filter-tags( [
        $!object.split(/ [\s || <punct>]+ /).Slip,
        ($!meta-data<path> // $!meta-data<url> // $!meta-data<uri> // '').split(
            / [\s || <punct>]+ /
        ).Slip,
        $prev-tags.Slip
      ]
    );

    # save new set of tags
note "T: ", $tags;
note "S: $subdoc";
    $udata<tags> = $tags;
    self.set-metameta( $udata, :$subdoc);
  }

  #-----------------------------------------------------------------------------
  multi method is-in-db ( List:D $query --> Bool ) {

    # use n to see the number of found records. 0 coerces to False,
    # True otherwise
    ? ( $!dbo.count: ( $query ) )<n>
  }

  multi method is-in-db ( BSON::Document:D $query --> Bool ) {

    # use n to see the number of found records. 0 coerces to False,
    # True otherwise
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

    # setup request. at the moment only a few types of path/url/uri
    my BSON::Document $req .= new;
    if ?$!meta-data<path> {
      $req<q> = (
        name => $!meta-data<name>,
        path => $!meta-data<path>,
      )
    }

    elsif ?$!meta-data<uri> {
      $req<q> = (
        name => $!meta-data<name>,
        uri => $!meta-data<uri>,
      )
    }

    elsif ?$!meta-data<url> {
      $req<q> = (
        name => $!meta-data<name>,
        url => $!meta-data<url>,
      )
    }

    $req<u> = ( '$set' => ( $subdoc => $!meta-data{$subdoc},),);
    $req<upsert> = False;

    # store in database only if record is found
    my BSON::Document $doc = $!dbo.update: [ $req ];

    if $doc<ok> {
      my $selected = $doc<n>;
      my $modified = $doc<nModified>;
      note "metameta $subdoc updated\n  selected = $selected\n",
           "  modified = $modified";
    }

    else {
      if $doc<writeErrors> {
        for $doc<writeErrors> -> $we {
          warn-message("metameta $subdoc update: " ~ $we<errmsg>);
          note "metameta data in $subdoc error" ~ $we<errmsg>;
        }
      }

      elsif $doc<errmsg> {
        warn-message("metameta $subdoc update: ", $doc<errmsg>);
        note "metameta $subdoc update: $doc<errmsg>";
      }

      else {
        warn-message("metameta $subdoc update: unknown error");
        note "metameta $subdoc update: unknown error";
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
  method !process-object( ) {

    my Library::MetaConfig::SkipDataList $sdl .= new;
    $!ignore-object = $sdl.filter( $!object.IO.absolute );
    return if $!ignore-object;

    my BSON::Document $doc .= new;

    # modify database if needed
    $!meta-data .= new;
    if self.specific-init-meta {

      #my Library::MetaConfig::TagFilterList $tfl .= new;
      #$!tags-filter = $tfl.get-tag-filter;

      # always select the meta-data collection in users database
      $!dbo .= new( :collection-key<meta-data>, :!root);

      $doc = self.update-meta;
    }

    else {
      $!ignore-object = True;
    }
  }

  #-----------------------------------------------------------------------------
  method !log-update-message ( BSON::Document:D $doc ) {

    if $doc<ok> == 1 {
      note "meta data of $!meta-data<name> updated";
    }

    else {
      note "updating meta data of $!meta-data<name> failed,\n",
           "error: $doc<errmsg>";
    }
  }
}
