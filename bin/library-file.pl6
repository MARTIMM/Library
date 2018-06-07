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

# needed by sub process-directory
my Bool $recursive;

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Store metadata about files.
#
# --et  extract tags from filename
# --r   Recursive search through directories

multi sub MAIN ( *@files-to-process, Bool :$r = False ) {

  $recursive := $r;

  # get the file and directory names and create Library::MetaData objects
  # any filtered objects are not returned and not saved in database
  my Seq $fp := gather for @files-to-process -> $object {
    process-directory($object);
  }

  # then add tags to the documents
  for $fp -> $meta-object {
    note $meta-object.perl;
    $meta-object.set-metameta-tags;
  }
}

#-------------------------------------------------------------------------------
# recursively gather objects from this object if directory.
# must run within a gather block.
# take returns Library::MetaData objects when the object is not ignored
sub process-directory ( Str $o ) {
  my Library::MetaData::Directory $mdir;
  my Library::MetaData::Directory $mfile;

  given $o.IO {

    # test if $o is a directory
    when :d {

      # first queue this directory object
      $mdir .= new(:object($o));
      take $mdir unless $mdir.ignore-object;

      # if a directory object is filtered out, al descendends are too
      return if $mdir.ignore-object;

      # then check if the contents of dir must be sought
      if $recursive {
        for dir($o) -> $object {
          if $object.d {
            # queue this directory and process
            $mdir .= new(:$object);
            take $mdir unless $mdir.ignore-object;
            process-directory($object.Str);
          }

          else {
            # queue this file
            $mfile .= new(:$object);
            take $mfile unless $mfile.ignore-object;
          }
        }
      }
    }

    when :f {
      # queue this file
      $mfile .= new(:object($o));
      take $mfile unless $mfile.ignore-object;
    }

    default {
      note "Special file $o ignored";
    }
  }
}
