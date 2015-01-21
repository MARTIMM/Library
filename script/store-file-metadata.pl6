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
  my @files-to-process = @files;                # Copy to rw-able array.

  say "R: {$recursive ?? 'Y' !! 'N'}";

  while @files-to-process.shift() -> $file      # for will not go past the
  {                                             # initial number of elements
    say "Processing {$file.IO.absolute()}";
    if $file.IO ~~ :d
    {
      my $directory := $file;                   # Alias to proper name
      if $recursive
      {
        my @new-files = dir( $directory, :Str);
        @files-to-process.push(@new-files);
      }

      else
      {
        say "Skip directory $directory";
      }

      next;
    }
    
    # Process plain files
    #
    elsif $file.IO ~~ :f
    {
      $meta.process-file($file);
    }
    
    # Ignore other type of files
    #
    else
    {
      say "File $file is ignored, it is a special type of file";
    }
  }
}

