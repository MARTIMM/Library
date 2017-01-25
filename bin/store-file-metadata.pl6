#!/usr/bin/env perl6

use v6;

use Library;
use Library::Metadata::Database;
use Library::Metadata::Object;

use MongoDB;
use BSON::Document;
use IO::Notification::Recursive;

#-------------------------------------------------------------------------------
#drop-send-to('mongodb');
#drop-send-to('screen');
#add-send-to( 'screen', :to($*ERR), :level(* >= MongoDB::Loglevels::Debug));

# setup config directory
my $cfg-dir = "$*HOME/.library";

mkdir $cfg-dir, 0o700 unless $cfg-dir.IO ~~ :d;
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

my Library::Metadata::Database $meta-db .= new();

# Allow switches after positionals. Pinched from the panda program. Now it is
# possible to make the sxml file executable with the path of this program.
#
say "Args: ", @*ARGS;
@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);
say "MArgs: ", @*ARGS;

#-------------------------------------------------------------------------------
# Program to store metadata about files.
#
# --h   Help info
# --k   supply keywords. Separated by commas or repetition of option
# --r   Recursive search through directories
#
sub MAIN ( *@files, Bool :$r = False, Str :$k ) {

  my Bool $recursive := $r;                     # Aliases to longer names
  my Library::Metadata::Object $lmo;

say "K: $k";
#  my Array[Str] $keys = [$k.split(/ \s* ',' \s* /)];
#  my Array $keys = [$k.join(',').split(/ \s* ',' \s* /)];
  my Array $keys = [$k.split(/ \s* ',' \s* /)];

  my @files-to-process = @files;                # Copy to rw-able array.

  if !?@files-to-process.elems {
    say "No files to process";
    exit(1);
  }

  for @files-to-process -> $file {

#    next if $file ~~ m/^ '.' /;

    # Process directories
    if $file.IO ~~ :d {

      # Alias to proper name if dir
      my $directory := $file;
      $lmo = $meta-db.update-meta( :object($directory), :type(OT-Directory));

      my BSON::Document $udata = $lmo.get-user-metadata;
      $udata<keys> = $keys;
      $lmo.set-user-metadata($udata);

      info-message("Stored dir {$file.IO.absolute()}");

      if $recursive {
        # only visible files
        my @new-files = dir( $directory, :Str).grep(/^ <-[.]> /);
        @files-to-process.push(@new-files);
      }

      else {
        info-message("Skip directory $directory"); 
      }

#      next;
    }

    # Process plain files
    elsif $file.IO ~~ :f {

      $lmo = $meta-db.update-meta( :object($file), :type(OT-File));

      my BSON::Document $udata = $lmo.get-user-metadata;
      $udata<keys> = $keys;
      $lmo.set-user-metadata($udata);

      info-message("Stored file {$file.IO.absolute()}");
    }

    # Ignore other type of files
    else {
      say "File $file is ignored, it is a special type of file";
    }
  }
}

