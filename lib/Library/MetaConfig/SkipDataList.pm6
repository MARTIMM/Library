use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Storage;
use Library::MetaConfig;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
class MetaConfig::SkipDataList does Library::MetaConfig {

  #-----------------------------------------------------------------------------
  method set-skip-filter (
    *@filter-list, Bool :$drop = False
    --> BSON::Document
  ) {

    my BSON::Document $doc;
    my Array $skips = self.get-skip-filter;
    my Bool $found = $skips.defined;
    $skips //= [];

    if $found {

      # remove tags when drop is True
      if $drop {
        $skips = [ $skips.List>>.eager.flat.unique.sort ];
#note "Sk 0: ", $skips.perl;
        for @filter-list -> $t is copy {
          if (my $index = $skips.first( $t, :k)).defined {
            $skips.splice( $index, 1);
          }
        }
      }

      else {
#note "Fl: ", @filter-list;
        $skips = [ ( |@$skips, |@filter-list )>>.eager.flat.unique.sort ];
      }

#note "Sk 1: ", $skips;
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
#note "Fl: ", @filter-list.perl;
        $skips = [ @filter-list.List>>.eager.flat.unique.sort ];
#note "Sk: ", $skips.perl;
        $doc = $!dbcfg.insert: [ (
            :config-type<skip-filter>,
            :$skips,
          ),
        ];
      }
    }

#note "DR: ", $doc.perl;
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
  method get-skip-filter ( --> Array ) {

    # find the config doc
    my $c = $!dbcfg.find(
      :criteria( (:config-type<skip-filter>, )),
      :number-to-return(1)
    );

    my BSON::Document $doc;
    $doc = $c.fetch;

    # return array or Array type
    $doc.defined ?? $doc<skips> !! Array
  }

  #-----------------------------------------------------------------------------
  method filter ( Str:D $path --> Bool ) {

    my Bool $filtered = False;

    my Array $skips = self.get-skip-filter;
    for @$skips -> $skip {
      if $path ~~ m/<$skip>/ {
        $filtered = True;
        last;
      }
    }

    $filtered
  }
}
