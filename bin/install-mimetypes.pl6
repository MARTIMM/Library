#!/usr/bin/env perl6

use v6;

#-------------------------------------------------------------------------------
# Read a list of file extensions amd their mimetype and store in database
# lines like
#   .mid audio/midi
#   .midi audio/midi
#   .kar audio/midi
# must be converted into documents like
#   _id => audio_midi
#   type => audio
#   subtype => midi
#   ext => [
#     .mid, .midi, .kar
#   ]

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;

use Library;
use Library::Configuration;


#-------------------------------------------------------------------------------
# Store the data in MongoDB Library. First get connection, database and
# collection. Drop the old collection before filling.

my Str $lib-dir = %*ENV<LIBRARY_CONFIG> // $*HOME.Str ~ "/.library';
initialize-library;

my Library::Configuration $cfg := $Library::lib-cfg;
my Str $client := $Library::client;

my Str $db-name = $cfg.database;
my Str $col-name = $cfg.config<library><collections><mimetypes>;
my MongoDB::Database $database = $client.database($db-name);
my MongoDB::Collection $collection = $database.collection($col-name);

#-------------------------------------------------------------------------------
sub MAIN ( ) {

}

#-------------------------------------------------------------------------------
# Get the html content. The content is saved on disk so test first
# if file exists.
#
my $content;
if 'mime-types-list.html'.IO ~~ :e {
  $content = slurp( 'mime-types-list.html', :!bin);
}

# if not found, get data from server
else {
#  if 0 {
#  my HTTP::Client $client .= new;
#  my $response = $client.get('http://www.freeformatter.com/mime-types-list.html');
#  if $response.success {
#    $content = $response.content;
#    my $mt = open( 'mime-types-list.html', :rw, :!bin);
#    $mt.print($content);
#    $mt.close;
#    spurt( 'mime-types-list.html', $content);
#  }
#  }

#  unlink 'mime-types-list.html';
  my $r = shell('wget http://www.freeformatter.com/mime-types-list.html');
}

# test for content
if !?$content {
  say "No content on server found";
  exit(1);
}

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
