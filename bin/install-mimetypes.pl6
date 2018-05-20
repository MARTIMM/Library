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

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;

use BSON::Document;

use Library;
use Library::Configuration;

#-------------------------------------------------------------------------------
# Program to store the data in MongoDB Library. First get connection,
# database and collection. Drop the old collection before filling.
#-------------------------------------------------------------------------------
sub MAIN ( ) {

  my Str $lib-dir = %*ENV<LIBRARY_CONFIG> // $*HOME.Str ~ '/.library';
  initialize-library;

  my Library::Configuration $cfg = $Library::lib-cfg;
  my MongoDB::Client $client = $Library::client;

  my Str $db-name = $cfg.database-name;
  my Str $col-name = $cfg.config<library><collections><mimetypes>;
  my MongoDB::Database $database = $client.database($db-name);
  my MongoDB::Collection $collection = $database.collection($col-name);

  # gather data into hash
  my Hash $mt-hash = {};
  # Get the list from mimetypes.txt
  my Str $content = 'doc/Mimetypes/mimetypes.txt'.IO.slurp;
  for $content.lines -> $line {

    my Str $ext;
    my Str $mimetype;
    my Str $mt-type;
    my Str $mt-subtype;
    ( $ext, $mimetype) = $line.split(/\s/);
    ( $mt-type, $mt-subtype) = $mimetype.split(/\//);
note "$ext, $mimetype, $mt-type, $mt-subtype";

    my Str $id = $mt-type ~ '-' ~ $mt-subtype;
    if $mt-hash{$id}:exists {
      $mt-hash{$id}<ext>.push: $ext;
    }

    else {
      $mt-hash{$id} = {};
      $mt-hash{$id}<type> = $mt-type;
      $mt-hash{$id}<subtype> = $mt-subtype;
      $mt-hash{$id}<ext> = [$ext];
    }
  }

  for $mt-hash.keys.sort -> $id {
    my BSON::Document $d .= new: (
      :_id($id),
      :type($mt-hash{$id}<type>),
      :subtype($mt-hash{$id}<subtype>),
      :ext($mt-hash{$id}<ext>),
    );

#note "DB: ", $database.perl;
    my BSON::Document $result-doc = $database.run-command: (
      :insert($col-name),
      :documents([ $d ]),
    );

    if $result-doc<ok> ~~ 1e0 {
      info-message("mimetype id '$id' stored");
    }

    else {
      warn-message("duplicate key, mimetype id '$id' is stored before");
note "Fail result: ", $result-doc.perl;
    }
  }
}

#-------------------------------------------------------------------------------

#`{{

if any($database.collection_names) ~~ $collection.name {
  say 'Drop collection {$collection.name}';
  $collection.drop();
}

# headers. F1 must be translated into F1a and F1b
my Hash $headers = {
  F0    => 'name',
  F1a   => 'type',
  F1b   => 'subtype',
  F2    => 'fileext',
  F3    => 'details1'
};

# Go through all tables
for $actions-object.tables.list -> $table {

  # Go through all rows
  for $table.keys -> $row {

    # Go through all fields
    my Hash $mime-data = {};
    for $table{$row}.keys -> $field {
      given $field {
        when 'F1' {
          my @type = $table{$row}{$field}.split('/');
          $mime-data{ $headers<F1a> } = @type[0];
          $mime-data{ $headers<F1b> } = @type[1];
        }

        when 'F2' {
          my Array $extensions = [$table{$row}{$field}.split( / \s* ',' \s* / )];
          $mime-data{ $headers{$field} } = $extensions;
        }

        default {
          $mime-data{ $headers{$field} } = $table{$row}{$field};
        }
      }
    }

    # Look it up first
    my Hash $doc = $collection.find_one({name => $mime-data<name>});
    $collection.insert($mime-data);# unless ?$doc;
    say '[', (?$doc ?? '-' !! 'x' ), "] $mime-data<fileext type subtype>";
  }
}
}}
