#!/usr/bin/env perl6

use v6;

use Library;
use Library::Metadata::Database;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;
use IO::Notification::Recursive;

#-------------------------------------------------------------------------------
modify-send-to( 'screen', :level(* >= MongoDB::Loglevels::Debug));

# setup config directory
my $cfg-dir = "$*HOME/.library";


mkdir $cfg-dir, 0o700 unless $cfg-dir.IO ~~ :d;
modify-send-to(
  'mongodb',
  :pipe("sort > $cfg-dir/store-file-metadata.log")
);

%*ENV<LIBRARY-CONFIG> = $cfg-dir;
my Str $cfg-file = "$cfg-dir/config.toml";
spurt( $cfg-file, Q:qq:to/EOCFG/);

  # MongoDB server connection
  uri         = "mongodb://"

  database    = 'Library'

  [ collection ]
    meta-data = 'Metadata'

  EOCFG

initialize-library();


# Allow switches after positionals. Pinched from the panda program. Now it is
# possible to make the sxml file executable with the path of this program.
#
#say "Args: ", @*ARGS;
@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);
#say "MArgs: ", @*ARGS;

#-------------------------------------------------------------------------------
# Program to store metadata about files.
#
# --*   Help info
# --k   supply keywords. Separated by commas or repetition of option
# --dk  remove keys when there are any
# --r   Recursive search through directories
#
sub MAIN ( *@files, Bool :$r = False, Str :$k = '', Str :$dk = '' ) {

  my Library::Metadata::Object $lmo;
  my Library::Metadata::Database $meta-db .= new();

  my Bool $recursive := $r;                     # Aliases to longer names
  my Array $keys = [$k.split(/ \s* ',' \s* /)];
  my Array $drop-keys = [$dk.split(/ \s* ',' \s* /)];

  my @files-to-process = @files;                # Copy to rw-able array.
  if !@files-to-process {

    info-message("No files to process");
    exit(0);
  }

  while shift @files-to-process -> $file {

    # Process directories
    if $file.IO ~~ :d {

      info-message("process dir {$file.IO.absolute()}");

      # Alias to proper name if dir
      my $directory := $file;
      $lmo = $meta-db.update-meta( :object($directory), :type(OT-Directory));

      my BSON::Document $udata = $lmo.get-user-metadata;
      $udata<keys> = $keys;
      $lmo.set-user-metadata($udata);

      if $recursive {

        # only 'content' files no '.' or '..'
        my @new-files = dir( $directory, :Str); #.grep(/^ <-[.]> <-[.]>? $/);
        @files-to-process.push(@new-files);
      }

      else {

        info-message("Skip directory $directory"); 
      }
    }

    # Process plain files
    elsif $file.IO ~~ :f {

      info-message("process file {$file.IO.absolute()}");

      $lmo = $meta-db.update-meta( :object($file), :type(OT-File));

      my BSON::Document $udata = $lmo.get-user-metadata;
      $udata<keys> = $keys;
      $lmo.set-user-metadata($udata);
    }

    # Ignore other type of files
    else {

      say "File $file is ignored, it is a special type of file";
    }
  }
}

