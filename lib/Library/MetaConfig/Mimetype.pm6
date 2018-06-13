use v6;

=begin comment
=end comment

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Storage;
use Library::MetaConfig;
use Library::Configuration;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
class MetaConfig::Mimetype does Library::MetaConfig {

  #-----------------------------------------------------------------------------
  multi submethod BUILD ( ) {

    $!dbcfg1 .= new( :collection-key<mimetypes>, :root);
    $!dbcfg2 .= new( :collection-key<extensions>, :root);
  }

  #-----------------------------------------------------------------------------
  method install-mimetypes (
    Bool :$check-all = False, Bool :$one-entry = False
  ) {

    # Get the list from resources mimetype file and store in database
    for %?RESOURCES<mimetypes>.IO.lines -> $line is copy {

      # remove comments
      $line ~~ s/\s* '#' .*? $//;

      # remove empty lines
      $line ~~ s:g/^ \s* $//;
      next if $line ~~ m/^$/;

      my @line-items = $line.split(/\s+/);
      my $doc = self.add-mimetype(
        @line-items.shift,
        :extensions(@line-items>>.fmt(".%s").grep(/.+/).sort.join(','))
      );

      if ?$doc and $doc<ok> == 0e0 {
        # mime found before. stop because others are inserted already
        # unless we have to check all entries
        last unless $check-all;
      }

      else {
        # we can safely assume that there is more to insert
        once {
          note "This wil take some time, please be patient";
        }
      }

      # for testing purposes
      last if $one-entry;
    }
  }

  #-----------------------------------------------------------------------------
  # get mimetype document
  multi method get-mimetype ( Str:D :$mimetype! --> BSON::Document ) {

    $!dbcfg1.find( :criteria( (:_id($mimetype),)) ).fetch;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # get mimetype document using extension reference when $get-mime-doc is True.
  # if False, return the extension document
  multi method get-mimetype (
    Str:D :$extension!, Bool :$get-mime-doc = True
    --> BSON::Document
  ) {

    my BSON::Document $m =
      $!dbcfg2.find( :criteria( (:_id($extension),)) ).fetch;

    $m = self.get-mimetype(:mimetype($m<mimetype_id>)) if ?$m and $get-mime-doc;

    $m
  }

  #-----------------------------------------------------------------------------
  method add-mimetype (
    Str:D $mimetype, Str :$extensions = '', Str :$exec = ''
    --> BSON::Document
  ) {

    my BSON::Document $doc;

    if self.get-mimetype(:$mimetype).defined {
      warn-message("duplicate key, mimetype id '$mimetype' is stored before");
    }

    else {
      my Str ( $mt-type, $mt-subtype) = $mimetype.split(/\//);
      my Array $exts = [ $extensions.split(/\s* \, \s*/).grep(/.+/).sort ];
      for @$exts -> $e is rw {
        $e ~~ s/^ \. //;
      }

      $doc = $!dbcfg1.insert: [ BSON::Document.new: (
          :_id($mimetype), :type($mt-type), :subtype($mt-subtype),
          :$exts, :$exec
        ),
      ];

      my Array $extdocs = [];
      for @$exts -> $e {
        unless self.get-mimetype(:extension($e)).defined {
            $extdocs.push( BSON::Document.new: (
              :_id($e), :mimetype_id($mimetype),
            )
          );
        }
      }

      $doc = $!dbcfg2.insert($extdocs);
      info-message("mimetype '$mimetype' stored") if $doc<ok> == 1e0;
    }

    # doc undefined when
    #   duplicate mimetype
    $doc
  }

  #-----------------------------------------------------------------------------
  method modify-mimetype (
    Str:D $mimetype, Str :$extensions = '', Str :$exec = ''
    --> BSON::Document
  ) {

    my BSON::Document $result;

    my BSON::Document $doc = self.get-mimetype(:$mimetype);

    # if there is a doc, we can update
    if ?$doc {
      my Array $exts;
      if ?$extensions {
        $exts = [ $extensions.split(/\s* \, \s*/).grep(/.+/).sort ];
        for @$exts -> $e is rw {
          $e ~~ s/^ \. //;
        }

        # take the difference to get all new extensions
        my @new-extensions = ($exts (-) $doc<exts>).keys;
        for @new-extensions -> $e is rw {
          # check extension document for its mimetype
          my BSON::Document $m = self.get-mimetype(
            :extension($e), :!get-mime-doc
          );

          if ?$m {
            if $m<_id> ne $mimetype {
              warn-message(
                "extension '$e' in use by mimetype '$mimetype', abort ..."
              );

              # return undefined doc
              last;
            }
          }

          else {
            my BSON::Document $doc = $!dbcfg2.insert(
              [ BSON::Document.new: ( :_id($e), :mimetype_id($mimetype)), ]
            );

            info-message("extension $e inserted");
          }
        }

        # take the difference again to get all old extensions to remove
        my @old-extensions = ($doc<exts> (-) $exts).keys;
        for @old-extensions -> $e is rw {
          my BSON::Document $doc = $!dbcfg2.delete(
            [ (:q(_id => $e), :limit(1)), ]
          );

          info-message("extension $e deleted");
        }
      }

      else {
        # no changes, keep old set
        $exts = $doc<exts> if ?$doc;
      }

      # update record
      $result = $!dbcfg1.update: [ (
          q => ( :_id($mimetype), ),
          u => ( '$set' => ( :$exts, :$exec,), ),
          upsert => False,
        ),
      ];
    }

    # result undefined means
    #   no record found to modify
    #   extension clash
    $result
  }

  #-----------------------------------------------------------------------------
  method remove-mimetype ( Str:D $mimetype --> BSON::Document ) {

    my BSON::Document $doc;
    my BSON::Document $m = self.get-mimetype(:$mimetype);
    if ?$m {
      for @($m<exts>) -> $e {
        $doc = $!dbcfg2.delete( [ (:q(_id => $e), :limit(1)), ] );
      }

      $doc = $!dbcfg1.delete( [ (:q(_id => $mimetype), :limit(1)), ] );
    }

    else {
      warn-message("mimetype $mimetype not found");
    }

    # doc undefined means
    #   no record found to remove
    $doc
  }

  # ==[ Private Stuff ]=========================================================
}
