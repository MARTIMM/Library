#!/usr/bin/env perl6
#
use v6;
use HTTP::Client;
#use Grammar::Tracer;

grammar Table-Grammar {
  token TOP { (<-[\<]>* ( <table> || \< <-[\<]>* ) )+ }

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

#  token data { <-[\<]>* }
#  token data { ( <-[\<]>* )* <?th-end> || <?td-end> }
  token data { .*? ( <?th-end> || <?td-end> ) }
#  token data { .? }

  token attribute { \s* <attr-name> '=' <attr-value> \s* }
  token attr-name { <[A..Za..z0..9\:\_\-]>+ }
  token attr-value { <[']> <-[']>* <[']> || <["]> <-["]>* <["]> }
}

class Table-Actions {
  has Array $.tables = [];
  has Int $.table-count = 0;

  has Hash $.table-content;
  has Int $.row-count;
  has Int $.field-count;
  has Hash $.headers;
  has Bool $.in-body;

  method table-start ( $match ) {
    $!table-content = {};
    $!row-count = 0;
    $!field-count = 0;
    $!headers = {};
    $!in-body = True;
  }

  method table-end ( $match ) {
    $!tables.push($!table-content);
    $!table-count++;
    $!table-content = {};
    $!row-count = 0;
    $!field-count = 0;
  }

  method table-hstart ( $match ) {
    $!in-body = False;
say "Start header, $!in-body";
  }

  method table-bstart ( $match ) {
    $!in-body = True;
  }

  method data ( $match ) {
    if $!in-body {
say "In body";
      $!table-content{'R' ~ $!row-count}{'F' ~ $!field-count} = $match.Str;
      $!field-count++;
    }

    else {
say "In header";
      $.headers{'F' ~ $!field-count} = $match.Str;
    }
  }

  method trd-end ( $match ) {
    $!row-count++;
    $!field-count = 0;
  }
}

# Test if file exists
#
my $content;
if 'mime-types-list.html'.IO ~~ :e {
  $content = slurp( 'mime-types-list.html', :!bin);
}

# Else get data from server
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
  
  unlink 'mime-types-list.html';
  my $r = shell('wget http://www.freeformatter.com/mime-types-list.html');
}

# Test for content
#
if !?$content {
  say "No content on server found";
  exit(1);
}

# Get data from table
#
# Name, MIME Type / Internet Media Type, File Extension, More Details
#
#my Str @table_entries;


#my regex data { <-[\<]>* };
#my regex tr-data { \s* \<td\><data>\<\/td\> \s* };
#my regex tr-entry { \s* \<tr\> <tr-data>+ \<\/tr\> \s* };
#my regex tr-entries { .* <tr-entry>+ .* };
#say 'D: ', '<td>Test data</td>' ~~ &tr-data;
#say 'E: ', '<tr> <td>Test data1</td> <td>Test data2</td> </tr>' ~~ &tr-entry;
#say 'C: ', $content ~~ &tr-entries;
#say 'P: ', Table.parse('<tr> <td>Test data1</td> <td>Test data2</td> </tr>');

my $h-text = q:to/EOT/;
jkdhfgkj kjd
<p> kjsdf
</p>

<table class='abc' id='1' title="t1">
  <thead>
    <tr>
      <th>jhg</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Test data1</td>
      <td>Test data2</td>
    </tr>
    <tr>
      <td>Test data3</td>
      <td>Test data4</td>
      <td>Test data5</td>
    </tr>
  </tbody>
</table>

jsdhfk sjhddkj dsjhfkjh

<table>
  <tr>
    <td>Test data1a</td>
    <td>Test data2a</td>
  </tr>
  <tr>
    <td>Test data1b</td>
    <td>Test data2b</td>
  </tr>
</table>

kjhkhjherk

<table class="bordered-table zebra-striped table-sort" style="font-size:11px;">
  <thead>
    <tr>
      <th nowrap="nowrap" style="width:250px;">Name</th>
      <th nowrap="nowrap">MIME Type / Internet Media Type</th>
      <th nowrap="nowrap">File Extension</th>
      <th nowrap="nowrap">More Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Andrew Toolkit</td>
      <td>application/andrew-inset</td>
      <td>N/A</td>
      <td><a title="What is a 'N/A' file?" href="http://www.iana.org/assignments/media-types/application/andrew-inset">IANA - Andrew Inset</a></td>
    </tr>
    <tr>
      <td>Applixware</td>
      <td>application/applixware</td>
      <td>.aw</td>
      <td><a title="What is a '.aw' file?" href="http://www.vistasource.com/en/apl.php">Vistasource</a></td>
    </tr>
    <tr>
      <td>Atom Syndication Format</td>
      <td>application/atom+xml</td>
      <td>.atom, .xml</td>
      <td><a title="What is a '.atom, .xml' file?" href="http://tools.ietf.org/html/rfc4287">RFC 4287</a></td>
    </tr>

  </tbody>
</table>

EOT
say "H: $h-text";
my Table-Actions $actions-object .= new();
Table-Grammar.subparse( $h-text, :actions($actions-object));
#Table-Grammar.subparse( $content, :actions($actions-object));

for $actions-object.tables.list -> $table {
  say "\nTable:";

  for $table.keys -> $row {
    say "  Row $row:";
    print "    ";
    for $table{$row}.keys -> $field {
      print "$field='", $table{$row}{$field}, "' ";
    }

    say '';
  }
}

