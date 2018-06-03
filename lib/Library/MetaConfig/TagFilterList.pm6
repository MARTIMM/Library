use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Storage;
use Library::MetaConfig;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
class MetaConfig::TagFilterList does Library::MetaConfig {

  #-----------------------------------------------------------------------------
  method set-tag-filter (
#    @filter-list, Array :$drop-tags --> BSON::Document
    @filter-list, Bool :$drop = False
    --> BSON::Document
  ) {

    my Array $tags;
    my BSON::Document $doc;

    # find the config doc for tag filters. If not found, create a new one.
    my $c = $!dbcfg.find(
      :criteria( (:config-type<tag-filter>, )),
      :number-to-return(1)
    );

    $doc = $c.fetch;

#note "SR: ", $doc.perl;

    # init if there isn't a document
    my Bool $found = $doc.defined;
    if $found {

      # remove tags when drop is True
      if $drop {
        $tags = [ ( ($doc<tags> // []).Slip).grep(/^...+/)>>.lc.unique.sort];
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
        $tags = [
          ( ($doc<tags> // []).Slip,
            |@filter-list
          ).grep(/^...+/)>>.lc.unique.sort
        ];
#note "FTags: @filter-list[*]";
#note "Tags: $tags[*]";
      }

      $doc = $!dbcfg.update: [ (
          q => ( :config-type<tag-filter>, ),
          u => ( '$set' => ( :$tags,),),
          upsert => False,
        ),
      ];
    }

    else {

      # dropping tags from an empty list is not useful
      if !$drop {
        $doc = BSON::Document.new;

        # filter tags shorter than 3 chars, lowercase convert, remove
        # doubles then sort
        $tags = [ @filter-list.grep(/^...+/)>>.lc.unique.sort ];

        $doc = $!dbcfg.insert: [ (
            :config-type<tag-filter>,
            :$tags,
          ),
        ];
      }
    }

#note "DR: ", $doc.perl;
    # test result of insert or update
    if $doc<ok> {
      my $selected = $doc<n>;

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
  method get-tag-filter ( --> Array ) {

    # find the config doc
    my $c = $!dbcfg.find(
      :criteria( (:config-type<tag-filter>, )),
      :number-to-return(1)
    );

    my BSON::Document $doc;
    $doc = $c.fetch;

    # init if there isn't a document
#    my Bool $found = $doc.defined;
    $doc //= BSON::Document.new;

    $doc<tags> // []
  }

  #-----------------------------------------------------------------------------
  method filter-tags ( Array:D $tags is copy, Array $drop-tags = [] --> Array ) {

    my $filter-list = self.get-tag-filter;

    # Filter tags shorter than 3 chars, lowercase convert, remove
    # doubles then sort
    $tags = [$tags.grep(/^...+/)>>.lc.unique.sort.List.Slip];

    # remove any tags
    for |@$filter-list, |@$drop-tags -> $t is copy {
      $t .= lc;
      if (my $index = $tags.first( $t, :k)).defined {
        $tags.splice( $index, 1);
      }
    }

    $tags
  }
}