#!/usr/bin/env perl6

use v6;

use Library;
use Library::Metadata::Database;
use Library::Config::TagsList;
use Library::Config::SkipList;
use Library::Metadata::Object::File;
use Library::Metadata::Object::Directory;

use MongoDB;
use BSON::Document;
#use IO::Notification::Recursive;

#-------------------------------------------------------------------------------
initialize-library();

#-------------------------------------------------------------------------------
# Allow switches after positionals. Pinched from the old panda program. Now it is
# possible to make the script files executable with the path of this program.
#say "Args: ", @*ARGS;
@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);
#say "MArgs: ", @*ARGS;

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
multi sub MAIN ( 'tag-filter', *@filter-list, Str :$dt = '' ) {

  my Array $drop-tags = [$dt.split(/ \s* <punct>+ \s* /)];

  # access config collection
  my Library::Config::TagsList $c .= new;
  $c.set-tag-filter( @filter-list, :$drop-tags);
}

#-------------------------------------------------------------------------------
# Store a list of regexes to filter on files and directories
# in the configuration collection
multi sub MAIN (
  'skip-filter', *@filter-list, Str :$ds = '', Bool :$dir = False
) {

  # drop skip from list. comma separated list of regexes. a comma in a
  # regex can be escaped with a '\' character.
  my Array $drop-skip = [
    $ds.split(/ \s* <!after '\\'> ',' \s* /)>>.subst(/\\/,'')
  ];

  # access config collection
  my Library::Config::SkipList $c .= new;
  $c.set-skip-filter( @filter-list, :$drop-skip, :$dir);
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Store metadata about files.
#
# --t   supply tags. Separated by commas or repetition of option
# --et  extract tags from filename
# --dt  remove tags when there are any
# --r   Recursive search through directories
#
multi sub MAIN (
  'fs', *@files, Bool :$r = False,
  Str :$t = '', Bool :$et = False, Str :$dt = '',
) {


#  my Library::Metadata::Object::File $mof;
#  my Library::Metadata::Object::Directory $mod;

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
  # take returns Library::Metadata::Object objects
  sub rec-dir ( Str $o ) {
    if $o.IO.d {
      # first take this directory
      take Library::Metadata::Object::Directory.new(:object($o));

      # then check if the contents of dir must be sought
      if $recursive {
        for dir($o) -> $object {
          if $object.d {
            take Library::Metadata::Object::Directory.new(:$object);
            rec-dir($object.Str);
          }

          else {
            take Library::Metadata::Object::File.new(:$object);
          }
        }
      }
    }

    elsif $o.IO.f {
      # take this file
      take Library::Metadata::Object::File.new(:object($o));
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
