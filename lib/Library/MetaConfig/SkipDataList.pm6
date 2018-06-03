use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Storage;
use Library::MetaConfig;

use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
class MetaConfig::SkipDataList does Library::MetaConfig {

  #----------------------------------------------------------------------------
  method set-skip-filter (
    @filter-list, Bool :$drop = False
    --> BSON::Document
  ) {

    my BSON::Document $doc;
    my Array $skips = self.get-skip-filter;
    my Bool $found = $skips.defined;
    $skips //= [];

    if $found {

      # remove tags when drop is True
      if $drop {
        $skips = [ $skips.grep(/^...+/)>>.lc.unique.sort ];
        for @filter-list -> $t is copy {
          $t .= lc;
          if (my $index = $skips.first( $t, :k)).defined {
            $skips.splice( $index, 1);
          }
        }
      }

      else {
        $skips = [ ( |@$skips, |@filter-list )>>.unique.sort ];
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
        $doc = BSON::Document.new;

        $skips = [ @filter-list>>.unique.sort ];

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

#`{{
    my Str $skip-field = $dir ?? 'dirskip' !! 'fileskip';

    # find the config doc
    my $c = $!dbcfg.find(
      :criteria( (:config-type<skip-filter>, )),
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
            :config-type<skip-filter>,
          ),

          u => ( '$set' => ( $skip-field => $skip,),),
          upsert => False,
        ),
      ];
    }

    else {
      $doc = $!dbcfg.insert: [ (
          :config-type<skip-filter>,
          $skip-field => $skip,
        ),
      ];
    }

#note $doc.perl;
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
}}
  }

  #----------------------------------------------------------------------------
  #method get-skip-filter ( Bool :$dir = False --> Array ) {
  method get-skip-filter ( --> Array ) {

    #my Str $skip-field = $dir ?? 'dirskip' !! 'fileskip';

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
}
