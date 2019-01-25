use v6;

=begin comment
  Skip filter list is an array of regexpresions  which are used to filter path
  objects. The list is made unique and is sorted before it is stored. The
  collection where it is stored is decided by the role Library::MetaConfig.
=end comment

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::MetaConfig;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

#-------------------------------------------------------------------------------
class MetaConfig::SkipDataList does Library::MetaConfig {

  #-----------------------------------------------------------------------------
  method set-filter (
    *@filter-list, Bool :$drop = False
    --> BSON::Document
  ) {

    my BSON::Document $doc;
    my Array $skips = self.get-filter;
    my Bool $found = $skips.defined;
    $skips //= [];

    if $found {

      # remove tags when drop is True
      if $drop {
        $skips = [ $skips.List>>.eager.flat.unique.sort ];
        for @filter-list -> $t is copy {
          if (my $index = $skips.first( $t, :k)).defined {
            $skips.splice( $index, 1);
          }
        }
      }

      else {
        $skips = [ ( |@$skips, |@filter-list )>>.eager.flat.unique.sort ];
      }

      $doc = $!dbcfg.update: [ (
          q => ( :config-type<skip-filter>, ),
          u => ( '$set' => ( :$skips,),),
          upsert => False,
        ),
      ];
    }

    else {
      # no use in dropping skip specs when there isn't a list
      if !$drop {
        # need .eager.flat to get rid of (x).Seq items. in TagFilterList
        # .lc does that at the same time.
        $skips = [ @filter-list.List>>.eager.flat.unique.sort ];
        $doc = $!dbcfg.insert: [ (
            :config-type<skip-filter>,
            :$skips,
          ),
        ];
      }
    }

    # test result of insert or update
    if $doc<ok> {
      if $doc<nModified>.defined {
        info-message("skip spec config update: modified tags");
      }

      else {
        info-message("skip spec config update: inserted new tags");
      }
    }

    else {
      if $doc<writeErrors> {
        for $doc<writeErrors> -> $we {
          warn-message("skip spec config update: " ~ $we<errmsg>);
        }
      }

      elsif $doc<errmsg> {
        warn-message("skip spec config update: ", $doc<errmsg>);
      }

      else {
        warn-message("skip spec config update: unknown error");
      }
    }

    $doc
  }

  #-----------------------------------------------------------------------------
  method get-filter ( --> Array ) {

    # find the config doc
    my MongoDB::Cursor $c = $!dbcfg.find:
       (:config-type<skip-filter>, ), :limit(1);

    my BSON::Document $doc;
    $doc = $c.fetch;

    # return array or Array type
    $doc.defined ?? $doc<skips> !! Array
  }

  #-----------------------------------------------------------------------------
  method filter ( Str:D $path --> Bool ) {

    my Bool $filtered = False;

    my Array $skips = self.get-filter;
    if $skips.defined {
      for @$skips -> $skip {
        if $path ~~ m/<$skip>/ {
          $filtered = True;
          last;
        }
      }
    }

    $filtered
  }
}
