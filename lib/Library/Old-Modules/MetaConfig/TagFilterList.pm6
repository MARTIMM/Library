use v6;

=begin comment
  Tag filter list is an array of words which are used to filter words found in
  another list. The words must have at least 3 characters to enter in the list.
  The words are all converted to lowercase and finally the list is sorted
  before it is stored. The collection where it is stored is decided by the role
  Library::MetaConfig
=end comment

#-------------------------------------------------------------------------------
use Library;
use Library::MetaConfig;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

#-------------------------------------------------------------------------------
unit class Library::MetaConfig::TagFilterList:auth<github:MARTIMM>;
also does Library::MetaConfig;

has Regex $!grep-filter = /^ <alpha> ** 3..*/;

#-----------------------------------------------------------------------------
method set-filter (
  *@filter-list, Bool :$drop = False
  --> BSON::Document
) {

  my BSON::Document $doc;
  my Array $tags = self.get-filter;

  # init if there isn't a document
  my Bool $found = $tags.defined;
  $tags //= [];
  if $found {

    # remove tags when drop is True
    if $drop {
      $tags = [ $tags.grep($!grep-filter)>>.lc.unique.sort ];
      for @filter-list -> $t is copy {
        $t .= lc;
        if (my $index = $tags.first( $t, :k)).defined {
          $tags.splice( $index, 1);
        }
      }
    }

    else {
      # filter tags shorter than 3 chars, lowercase convert, remove
      # doubles then sort
      $tags = [ (
          |@$tags, |@filter-list
        ).grep($!grep-filter)>>.lc.unique.sort
      ];
    }

    $doc = $!dbcfg.update: [ (
        q => ( :config-type<tag-filter>, ),
        u => ( '$set' => ( :$tags,),),
        upsert => True,
      ),
    ];
  }

  else {

    # dropping tags from an empty list is not useful
    if !$drop {
      # filter tags shorter than 3 chars, lowercase convert, remove
      # doubles then sort
      $tags = [ @filter-list.grep($!grep-filter)>>.lc.unique.sort ];
      $doc = $!dbcfg.insert: [ (
          :config-type<tag-filter>,
          :$tags,
        ),
      ];
    }
  }

  # test result of insert or update
  if $doc<ok> {
    if $doc<nModified>.defined {
      info-message("tags config update: modified tags");
    }

    else {
      info-message("tags config update: inserted new tags");
    }
  }

  else {
    if $doc<writeErrors> {
      for $doc<writeErrors> -> $we {
        warn-message("tags config update: " ~ $we<errmsg>);
      }
    }

    elsif $doc<errmsg> {
      warn-message("tags config update: ", $doc<errmsg>);
    }

    else {
      warn-message("tags config update: unknown error");
    }
  }

  $doc
}

#-----------------------------------------------------------------------------
method get-filter ( --> Array ) {

  # find the config doc
  my MongoDB::Cursor $c = $!dbcfg.find:
    (:config-type<tag-filter>, ), :limit(1);

  return [] unless ?$c;

  my BSON::Document $doc = $c.fetch;

  # return array or Array type
  $doc.defined ?? $doc<tags> !! Array
}

#-----------------------------------------------------------------------------
method filter ( Array:D $tags is copy --> Array ) {

  my Array $filter-list = self.get-filter;

  # filter tags shorter than 3 chars, hexnumbers, lowercase convert, remove
  # doubles then sort
  $tags = [$tags.grep($!grep-filter)>>.lc.unique.sort.List.Slip];

  # remove any tags
  if $filter-list.defined {
    for @$filter-list -> $t is copy {
      $t .= lc;
      if (my $index = $tags.first( $t, :k)).defined {
        $tags.splice( $index, 1);
      }
    }
  }

  $tags
}
