use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Database;
use Library::Config;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
class Config::TagsList does Library::Config {

  #----------------------------------------------------------------------------
  method set-tag-filter ( @filter-list, Array :$drop-tags --> BSON::Document ) {

    # find the config doc
    my $c = $!dbcfg.find(
      :criteria( (:config-type<tag-filter>, )),
      :number-to-return(1)
    );

note "C: ", ($c // 'no cursor').perl;

    my BSON::Document $doc;
    $doc = $c.fetch;

    # init if there isn't a document
    my Bool $found = $doc.defined;
    $doc //= BSON::Document.new;

    # filter tags shorter than 3 chars, lowercase convert, remove
    # doubles then sort
    my Array $tags = [
      (($doc<tags> // []).Slip, |@filter-list).grep(/^...+/)>>.lc.unique.sort
    ];

    # remove any tags
    for @$drop-tags -> $t is copy {
      $t .= lc;
      if (my $index = $tags.first( $t, :k)).defined {
note "Filter $t: $index";
        $tags.splice( $index, 1);
      }
    }
note "A: $found, ", $tags;

    if $found {
      $doc = $!dbcfg.update: [ (
          q => (
            :config-type<tag-filter>,
          ),

          u => ( '$set' => ( :$tags,),),
          upsert => False,
        ),
      ];
    }

    else {
      $doc = $!dbcfg.insert: [ (
          :config-type<tag-filter>,
          :$tags,
        ),
      ];
    }

note $doc.perl;
    if $doc<ok> {
      my $selected = $doc<n>;

      if (my $modified = $doc<nModified>).defined {
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

  #----------------------------------------------------------------------------
  method get-tag-filter ( --> Array ) {

    # find the config doc
    my $c = $!dbcfg.find(
      :criteria( (:config-type<tag-filter>, )),
      :number-to-return(1)
    );

note "C: ", ($c // 'no cursor').perl;

    my BSON::Document $doc;
    $doc = $c.fetch;

    # init if there isn't a document
#    my Bool $found = $doc.defined;
    $doc //= BSON::Document.new;

note "Doc: ", $doc.perl;
    $doc<tags> // []
  }

  #----------------------------------------------------------------------------
  method filter-tags ( Array:D $tags is copy, Array $drop-tags = [] --> Array ) {

    my $filter-list = self.get-tag-filter;

    # Filter tags shorter than 3 chars, lowercase convert, remove
    # doubles then sort
    $tags = [$tags.grep(/^...+/)>>.lc.unique.sort.List.Slip];

note "FL: ", $filter-list, $drop-tags;
    # remove any tags
    for |@$filter-list, |@$drop-tags -> $t is copy {
      $t .= lc;
      if (my $index = $tags.first( $t, :k)).defined {
note "Filter $t: $index";
        $tags.splice( $index, 1);
      }
    }

note "TL: ", $tags;

    $tags
  }
}
