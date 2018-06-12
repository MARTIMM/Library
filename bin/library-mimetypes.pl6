#!/usr/bin/env perl6

use v6;

#-------------------------------------------------------------------------------
# Read a list of file extensions amd their mimetype and store in database
# lines like
#   .mid audio/midi
#   .midi audio/midi
#   .kar audio/midi
# must be converted into documents like
#   _id => audio-midi
#   type => audio
#   subtype => midi
#   ext => [
#     .mid, .midi, .kar
#   ]
#
# and several others like
#   _id => .mid
#   mimetype_id => audio-midi
# ...

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;

use BSON::Document;

use Library;
use Library::Configuration;
use Library::MetaConfig::Mimetype;

#-------------------------------------------------------------------------------
# Program to store the data in MongoDB Library. First get connection,
# database and collection. Drop the old collection before filling.
#-------------------------------------------------------------------------------

my Str $lib-dir = %*ENV<LIBRARY_CONFIG> // $*HOME.Str ~ '/.library';
initialize-library;
my Library::MetaConfig::Mimetype $m .= new;

#-------------------------------------------------------------------------------
multi sub MAIN (
  Str:D $mimetype, Str :$exts = '', Str :$exec = '', Bool:D :$add!
) {

  my BSON::Document $doc = $m.add-mimetype(
    $mimetype, :extensions($exts), :$exec
  );

  if $doc.defined {
    note "Mimetype $mimetype added";
  }

  else {
    note "Failed to add a mimetype, there is a duplicate";
  }
}

#-------------------------------------------------------------------------------
multi sub MAIN (
  Str:D $mimetype, Str :$exts = '', Str :$exec = '', Bool:D :$mod!
) {

  my BSON::Document $doc = $m.modify-mimetype(
    $mimetype, :extensions($exts), :$exec
  );

  if $doc.defined {
    note "Mimetype $mimetype modified";
  }

  else {
    note "Failed to modify a mimetype, not found or an extension clash";
  }
}

#-------------------------------------------------------------------------------
multi sub MAIN ( Str:D $mimetype, Bool:D :$rem! ) {

  my BSON::Document $doc = $m.remove-mimetype($mimetype);
  if $doc.defined {
    note "Mimetype $mimetype removed";
  }

  else {
    note "Failed to remove a mimetype, not found";
  }
}

#-------------------------------------------------------------------------------
multi sub MAIN ( Str:D $mimetype, Bool:D :$get! ) {

  my BSON::Document $doc = $m.get-mimetype(:$mimetype);
  if $doc.defined {
    note "Result: \n", $doc.perl;
  }

  else {
    note "Mimetype not found";
  }
}

#-------------------------------------------------------------------------------
multi sub MAIN ( Bool:D :$install! ) {

  $m.install-mimetypes(:check-all);
}
