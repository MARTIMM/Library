#!/usr/bin/env perl6
#`{{
  Perl6 datablock are not yet implemented so $=data will generate an error.
  After some testing I also found that the data between e.g. '=begin data' and
  '=end data' are scooped up into one single string without any newline (\n).
  This, I find, is an important character needed to separate lines. so
  =begin data
  a 1
  b 2
  =end data
  is stored somewhere in the pod structure as "a 1 b 2" which is not easily
  processable later on.

  Studying the comment structures however, the newline character is kept
  in thos structures. The below code processes such a structure and adds some
  keys to the comments to have some control on what to process

  e.g.
  =begin comment :!comment :some-key

  # two datalines of interesting data
  foo 1
  bar 2

  =end comment

  This can then be called by get-data('some-key') to get the data in the comment
  blocks. Here, three things are important;
  1) :!comment is checked by the sub so it must be there. It is also a sign to
     the reader that this block is not used to show comments
  2) :some-key is the key to use to search for data. More than one data block
     is then possible and other (real) comments are not processed.
  3) The sub is filtering out empty lines and comment lines (starting with '#')
     These are the last few lines in the sub. You can leave that out if you like
}}

use v6;

# Program returns;
#Data line: foo 1
#Data line: bar 2

my Str $foo-data = get-data('fooDataBlock');
for $foo-data.lines -> $line {
  say "Data line: $line";
}

# data block
=begin comment :!comment :type<fooDataBlock>

# test van data
foo 1

# second line
bar 2

=end comment

# the sub that returns the data from the block
sub get-data ( Str:D $content-key --> Str ) {

  my Str $content;

  # search through the pod structure
  for @$=pod -> $pd {

    # search for 1) pod comment block, 2) :!comment and 3) the users key
    if $pd ~~ Pod::Block::Comment and
       !$pd.config<comment> and
       $pd.config<type> eq $content-key {

      $content = $pd.contents[0];
      last;
    }
  }

  # remove comments
  $content ~~ s:g/\s* '#' .*? $$//;

  # remove empty lines
  $content ~~ s:g/^^ \s* $$//;
  $content ~~ s:g/\n\n+/\n/;
  $content ~~ s:g/^\n+//;
  $content ~~ s:g/\n+$//;

  $content
}
