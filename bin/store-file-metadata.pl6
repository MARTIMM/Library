#!/usr/bin/env perl6
#
use v6;


use Library::File-metadata-manager;

#-------------------------------------------------------------------------------
#
my Library::File-metadata-manager $file-meta .= new();

# Allow switches after positionals. Pinched from the panda program. Now it is
# possible to make the sxml file executable with the path of this program.
#
@*ARGS = @*ARGS.grep(/^ '-'/), @*ARGS.grep(/^ <-[-]>/);

#| Program to store metadata about files.
sub MAIN ( *@files, Bool :$r = False ) {
  my Bool $recursive := $r;                     # Alias to longer name
  my @files-to-process = @files;                # Copy to rw-able array.

  my Array $sts_symbols = [<! s n u a>];        # See File-metadata-manager

  while @files-to-process.shift() -> $file {    # for will not go past the
                                                # initial number of elements

    # Process directories
    #
    if $file.IO ~~ :d {
      my $directory := $file;                   # Alias to proper name
      $file-meta.process-directory($directory);
      say '[', $sts_symbols[$file-meta.status], ']', " {$file.IO.absolute()}";

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
      say '[', $sts_symbols[$file-meta.status], ']', " {$file.IO.absolute()}";
    }

    # Ignore other type of files
    #
    else {
      say "File $file is ignored, it is a special type of file";
    }
  }
}

