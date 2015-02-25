#!/usr/bin/env perl6
#
use v6;

use Library::File-metadata-manager;

#------------------------------------------------------------------------------
#
my Library::File-metadata-manager $file-meta .= new();

#| Program to store metadata about files.
sub MAIN ( **@files, Bool :$r = False ) {
  my Bool $recursive := $r;                     # Alias to longer name
  my @files-to-process = @files;                # Copy to rw-able array.

  while @files-to-process.shift() -> $file {    # for will not go past the
                                                # initial number of elements
    say "Processing {$file.IO.absolute()}";

    # Process directories
    #
    if $file.IO ~~ :d {
      my $directory := $file;                   # Alias to proper name
      $file-meta.process-directory($directory);
      if $recursive {
        my @new-files = dir( $directory, :Str);
        @files-to-process.push(@new-files);
      }

      else {
        say "Skip directory $directory";
      }

      next;
    }
    
    # Process plain files
    #
    elsif $file.IO ~~ :f {
      $file-meta.process-file($file);
    }

    # Ignore other type of files
    #
    else {
      say "File $file is ignored, it is a special type of file";
    }
  }
}

