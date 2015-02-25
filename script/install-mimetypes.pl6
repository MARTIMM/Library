#!/usr/bin/env perl6
#-------------------------------------------------------------------------------
# Get a mimtype info from http://www.freeformatter.com/mime-types-list.html
# and store them in MongoDB database Library and collection mimetypes.
#-------------------------------------------------------------------------------
use v6;
use HTTP::Client;
use MongoDB;
use Library;
#use Grammar::Tracer;

#-------------------------------------------------------------------------------
# Define a grammer to read a html table
#
grammar Table-Grammar {
  token TOP { (<-[\<]>* ( <table> || \< <-[\<]>* ) )+ }

  # Table can have a header and body or plain records. Col specs are ignored
  # for the moment
  #
  token table { <table-start> \s* ( <table-head> \s* <table-body> || <trd-entry>+ ) \s* <table-end> }
  token table-start { \<table <attribute>* \> }
  token table-end { \<\/table\> }

  token table-head { <table-hstart> <trh-entry>* <table-hend> }
  token table-hstart { \<thead\> }
  token table-hend { \<\/thead\> }

  token trh-entry { \s* <trh-start> <trh-data>* <trh-end> \s* }
  token trh-start { \<tr\> }
  token trh-end { \<\/tr\> }

  token trh-data { \s* <th-start> <data> <th-end> \s* }
  token th-start { \<th <attribute>* \> }
  token th-end { \<\/th\> }

  token table-body { <table-bstart> <trd-entry>* <table-bend> }
  token table-bstart { \<tbody\> }
  token table-bend { \<\/tbody\> }

  token trd-entry { \s* <trd-start> <trd-data>* <trd-end> \s* }
  token trd-start { \<tr\> }
  token trd-end { \<\/tr\> }

  token trd-data { \s* <td-start> <data> <td-end> \s* }
  token td-start { \<td <attribute>* \> }
  token td-end { \<\/td\> }

  # In the data field there can be other tags, so be not-greedy and look for
  # the proper end tags
  #
  token data { .*? ( <?th-end> || <?td-end> ) }

  token attribute { \s* <attr-name> '=' <attr-value> \s* }
  token attr-name { <[A..Za..z0..9\:\_\-]>+ }
  token attr-value { <[']> <-[']>* <[']> || <["]> <-["]>* <["]> }
}

# The actions to perform when tokens are found
#
class Table-Actions {
  has Array $.tables = [];
  has Int $.table-count = 0;

  has Hash $.table-content;
  has Int $.row-count;
  has Int $.field-count;
  has Bool $.in-body;

  method table-start ( $match ) {
    $!table-content = {};
    $!row-count = 0;
    $!field-count = 0;
    $!in-body = True;
  }

  method table-end ( $match ) {
    $!tables.push($!table-content);
    $!table-count++;
  }

  method table-hstart ( $match ) {
    $!in-body = False;
  }

  method table-bstart ( $match ) {
    $!in-body = True;
  }

  method data ( $match ) {
    if $!in-body {
      $!table-content{'R' ~ $!row-count}{'F' ~ $!field-count} = $match.Str;
      $!field-count++;
    }
  }

  method trd-end ( $match ) {
    $!row-count++;
    $!field-count = 0;
  }
}

#------------------------------------------------------------------------------
# Get the html content. The content is saved on disk so test first
# if file exists.
#
my $content;
if 'mime-types-list.html'.IO ~~ :e {
  $content = slurp( 'mime-types-list.html', :!bin);
}

# If not found, get data from server
#
else {
  if 0 {
  my HTTP::Client $client .= new;
  my $response = $client.get('http://www.freeformatter.com/mime-types-list.html');
  if $response.success {
    $content = $response.content;
    my $mt = open( 'mime-types-list.html', :rw, :!bin);
    $mt.print($content);
    $mt.close;
#    spurt( 'mime-types-list.html', $content);
  }
  }

#  unlink 'mime-types-list.html';
  my $r = shell('wget http://www.freeformatter.com/mime-types-list.html');
}

# Test for content
#
if !?$content {
  say "No content on server found";
  exit(1);
}

#------------------------------------------------------------------------------
# Get data from table
#
my Table-Actions $actions-object .= new();
Table-Grammar.subparse( $content, :actions($actions-object));

#------------------------------------------------------------------------------
# Store the data in MongoDB Library
#
my $cfg = $Library::cfg;
my MongoDB::Database $lib-db = $Library::connection.database($cfg.get('database'));
my MongoDB::Collection $mime-cl = $lib-db.collection($cfg.get('collections')<mimetypes>);

# headers. F1 must be translated into F1a and F1b
#
my Hash $headers = {
  F0 => 'name',
  F1a => 'type',
  F1b => 'subtype',
  F2 => 'fileext',
  F3 => 'details1'
};

# Go through all tables
#
for $actions-object.tables.list -> $table {

  # Go through all rows
  #
  for $table.keys -> $row {

    # Go through all fields
    #
    my Hash $mime-data = {};
    for $table{$row}.keys -> $field {
      if $field eq 'F1' {
        my @type = $table{$row}{$field}.split('/');
        $mime-data{ $headers<F1a> } = @type[0];
        $mime-data{ $headers<F1b> } = @type[1];
      }
      
      else {
        $mime-data{ $headers{$field} } = $table{$row}{$field};
      }
    }

    # Look it up first
    #
    my Hash $doc = $mime-cl.find_one({name => $mime-data<name>});
    $mime-cl.insert($mime-data) unless ?$doc;
    say '[', (?$doc ?? '-' !! 'x' ), "] $mime-data<fileext type subtype>";
  }
}

