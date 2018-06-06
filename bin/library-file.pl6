#!/usr/bin/env perl6

use v6;

use Library;
use Library::MetaData::File;
use Library::MetaData::Directory;

use MongoDB;
use BSON::Document;
#use IO::Notification::Recursive;

#-------------------------------------------------------------------------------
initialize-library();

#-------------------------------------------------------------------------------
# Allow switches after positionals. Pinched from the old panda program. Now it
# is possible to make the script files executable with the path of this program.
#say "Args: ", @*ARGS;
@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);
#say "MArgs: ", @*ARGS;

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Store metadata about files.
#
# --et  extract tags from filename
# --r   Recursive search through directories
#
#TODO do we need these?
# --t   supply tags. Separated by commas or repetition of option
# --dt  remove tags when there are any
#
multi sub MAIN (
  *@files, Bool :$r = False,
  Str :$t = '', Bool :$et = False, Str :$dt = '',
) {

#  my Library::MetaData::File $mof;
#  my Library::MetaData::Directory $mod;

  my Bool $recursive := $r;                     # Aliases to longer name
  my Array $arg-tags = [$t.split(/:s \s* <punct>+ \s* /)];
  my Array $drop-tags = [$dt.split(/ \s* <punct>+ \s* /)];

  my @files-to-process = @files;                # Copy to rw-able array.
  if !@files-to-process {

    info-message("No files to process");
    exit(0);
  }

  # recursively gather objects from this object if directory.
  # must run within a gather block.
  # take returns Library::MetaData objects
  sub rec-dir ( Str $o ) {
    if $o.IO.d {
      # first take this directory
      take Library::MetaData::Directory.new(:object($o));

      # then check if the contents of dir must be sought
      if $recursive {
        for dir($o) -> $object {
          if $object.d {
            take Library::MetaData::Directory.new(:$object);
            rec-dir($object.Str);
          }

          else {
            take Library::MetaData::File.new(:$object);
          }
        }
      }
    }

    elsif $o.IO.f {
      # take this file
      take Library::MetaData::File.new(:object($o));
    }

    else {
      warn-message("Special file $o ignored");
    }
  }

  my Seq $fp := gather for @files-to-process -> $object {
    rec-dir($object);
  }

  for $fp -> $meta-object {
    say $meta-object.perl;
    $meta-object.set-metameta-tags( :$et, :$arg-tags, :$drop-tags);
  }

#`{{
  while shift @files-to-process -> $file {

    # Process directories
    if $file.IO ~~ :d {

      # Alias to proper name if dir
      my $directory := $file;

      info-message("process directory '$directory'");

      $mod .= new(:object($directory));
      $mod.set-metameta-tags( $directory, :$et, :$arg-tags, :$drop-tags);

      if $recursive {

        # only 'content' files no '.' or '..'
        my @new-files = dir( $directory).List>>.absolute;

        @files-to-process.push(|@new-files);
      }

      else {

        info-message("Skip directory $directory");
      }
    }

    # Process plain files
    elsif $file.IO ~~ :f {

      info-message("process file $file");

      $mof .= new(:object($file));
      $mof.set-metameta-tags( $file, :$et, :$arg-tags, :$drop-tags);
    }

    # Ignore other type of files
    else {

      warn-message("File $file is ignored, it is a special type of file");
    }
  }
}}
}
