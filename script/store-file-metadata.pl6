#!/usr/bin/env perl6
#
use v6;

use Library::File-metadata-manager;

#------------------------------------------------------------------------------
#
my Library::File-metadata-manager $meta .= new();

#| Program to store metadata about a file.
sub MAIN ( **@files, :$rec = False )
{
  my $recursive := $rec;                        # Alias to longer name
  my @*files-to-process = @files;               # Copy to rw-able array.
say "Elems: {@*files-to-process.elems}";

  say "R: {$recursive ?? 'Y' !! 'N'}";

  for @*files-to-process -> $file
  {
    say "Processing {$file.IO.absolute()}";
    if $file.IO ~~ :d
    {
      my $directory := $file;                   # Alias to proper name
      if $recursive
      {
        my @new-files = dir( $directory, :Str);
        push @*files-to-process, @new-files;
say "Elems: {@*files-to-process.elems}";
      }

      else
      {
        say "Skip directory $directory";
      }
      
      next;
    }
  }
}

