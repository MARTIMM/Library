#!/usr/bin/env -S raku -Ilib

use v6.d;
use XML;

#-------------------------------------------------------------------------------
my XML::Element $e;
#$e .= new(:name<gresources>);
#my XML::Document $root .= new( $e, :encoding<UTF-8>);
my XML::Document $root .= new(Q:q:to/EOXML/);
  <?xml version="1.0" encoding="UTF-8"?>
  <gresources/>
  EOXML

$e .= new(:name<gresource>);
$root.append($e);
$e.attribs<prefix> = '/io/github/martimm/library';

my $*path-prefix = 'xbin/resource-data';
add-file( $e, 'library-style', 'library-style.css', :compress);
add-file( $e, 'app-menu', 'application-menu.xml', :compress, :strip);
add-file( $e, 'help-about', 'about-dialog.xml', :compress, :strip);
#add-file( $e, 'db-skip', 'db-skip-dialog.xml', :compress, :strip);

"$*path-prefix/gen-resources.xml".IO.spurt($root.Str);
run 'glib-compile-resources', "$*path-prefix/gen-resources.xml";
"$*path-prefix/gen-resources.gresource".IO.move('resources/library.gresource');

#-------------------------------------------------------------------------------
sub add-file (
  XML::Element $parent, Str $alias, Str $fname, Bool :$compress, Bool :$strip
) {
  my XML::Element $e .= new(:name<file>);
  $e.attribs<alias> = $alias;
  $e.attribs<compressed> = 'true' if $compress;
  $e.attribs<preprocess> = 'xml-stripblanks' if $strip;
  $e.insert(XML::Text.new(:text("$*path-prefix/$fname")));
  $parent.append($e);
}
