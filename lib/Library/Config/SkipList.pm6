use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Database;
use Library::Config;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
class Config::SkipList does Library::Config {

  #----------------------------------------------------------------------------
  method set-skip-filter (
    @filter-list, Array :$drop-skip, Bool :$dir = False
    --> BSON::Document
  ) {

    my Str $skip-field = $dir ?? 'dirskip' !! 'fileskip';

    # find the config doc
    my $c = $!dbcfg.find(
      :criteria( (:config-type<skip-object>, )),
      :number-to-return(1)
    );

    my BSON::Document $doc;
    $doc = $c.fetch;

    # init if there isn't a document
    my Bool $found = $doc.defined;
    $doc //= BSON::Document.new;

    # filter skip regexes by removing doubles and sort
    my Array $skip = [
      (($doc{$skip-field} // []).Slip, |@filter-list).unique.sort
    ];

    # remove any skip regexes
    for @$drop-skip -> $t is copy {
      $t .= lc;
      if (my $index = $skip.first( $t, :k)).defined {
note "Skip $t: $index";
        $skip.splice( $index, 1);
      }
    }
note "A: $found, ", $skip;

    if $found {
      $doc = $!dbcfg.update: [ (
          q => (
            :config-type<skip-object>,
          ),

          u => ( '$set' => ( $skip-field => $skip,),),
          upsert => False,
        ),
      ];
    }

    else {
      $doc = $!dbcfg.insert: [ (
          :config-type<skip-object>,
          $skip-field => $skip,
        ),
      ];
    }

note $doc.perl;
    if $doc<ok> {
      my $selected = $doc<n>;

      if (my $modified = $doc<nModified>).defined {
        info-message("dir skip config update: modified skip list");
      }

      else {
        info-message("dir skip config update: inserted new skip list");
      }
    }

    else {
      if $doc<writeErrors> {
        for $doc<writeErrors> -> $we {
          warn-message("dir skip config update: " ~ $we<errmsg>);
        }
      }

      elsif $doc<errmsg> {
        warn-message("dir skip config update: ", $doc<errmsg>);
      }

      else {
        warn-message("dir skip config update: unknown error");
      }
    }

    $doc
  }

  #----------------------------------------------------------------------------
  method get-skip-filter ( --> Array ) {

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
