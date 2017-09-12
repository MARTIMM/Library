#!/usr/bin/env perl6

use v6;

use Library;
use Library::Metadata::Database;
use Library::Metadata::Object;
use Library::Metadata::Object::File;
use Library::Metadata::Object::Directory;

use MongoDB;
use BSON::Document;
use IO::Notification::Recursive;

#-------------------------------------------------------------------------------
# setup logging
#drop-send-to('mongodb');
#drop-send-to('screen');
modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));

# setup config directory
my $cfg-dir;
if %*ENV<LIBRARY-CONFIG>:exists and %*ENV<LIBRARY-CONFIG>.IO ~~ :d {
  $cfg-dir = %*ENV<LIBRARY-CONFIG>;
}

else {
  $cfg-dir = "$*HOME/.library";
  %*ENV<LIBRARY-CONFIG> = $cfg-dir;
}

mkdir $cfg-dir, 0o700 unless $cfg-dir.IO ~~ :d;
modify-send-to( 'mongodb', :pipe("sort > $cfg-dir/store-file-metadata.log"));

# set config file if needed
my Str $cfg-file = "$cfg-dir/config.toml";
spurt( $cfg-file, Q:qq:to/EOCFG/) unless $cfg-file.IO ~~ :r;

  # MongoDB server connection
  uri         = "mongodb://"
  database    = 'Library'
  recursive-scan-dirs = []

  [ collection ]
    meta-data = 'Metadata'

  EOCFG

initialize-library();


# Allow switches after positionals. Pinched from the old panda program. Now it is
# possible to make the script files executable with the path of this program.
#say "Args: ", @*ARGS;
@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);
#say "MArgs: ", @*ARGS;

#-------------------------------------------------------------------------------
# Program to store metadata about files.
#
# --*   Help info
# --t   supply tags. Separated by commas or repetition of option
# --et  extract tags from filename
# --dt  remove tags when there are any
# --r   Recursive search through directories
#
sub MAIN (
  *@files, Bool :$r = False,
  Str :$t = '', Bool :$et = False, Str :$dt = ''
) {

  my Library::Metadata::Object::File $mof;
  my Library::Metadata::Object::Directory $mod;

  my Bool $recursive := $r;                     # Aliases to longer name
  my Array $arg-tags = [$t.split(/:s \s* <punct>+ \s* /)];
  my Array $drop-tags = [$dt.split(/ \s* <punct>+ \s* /)];

  my @files-to-process = @files;                # Copy to rw-able array.
  if !@files-to-process {

    info-message("No files to process");
    exit(0);
  }

  while shift @files-to-process -> $file {

    # Process directories
    if $file.IO ~~ :d {

      # Alias to proper name if dir
      my $directory := $file;

      info-message("process directory '$directory'");

      $mod .= new(:object($directory));
      set-user-meta-data( $mod, $directory, :$et, :$arg-tags, :$drop-tags);

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
      set-user-meta-data( $mof, $file, :$et, :$arg-tags, :$drop-tags);
    }

    # Ignore other type of files
    else {

      warn-message("File $file is ignored, it is a special type of file");
    }
  }
}

#------------------------------------------------------------------------------
sub set-user-meta-data (
  Library::Metadata::Object:D $object, Str:D $object-name,
  Bool :$et = False, Array :$arg-tags = [], Array :$drop-tags = [],
) {

  my Array $tags = [];

  # get user meta data
  my BSON::Document $udata = $object.get-user-metadata;
  my Array $prev-tags = $udata<tags> // [];

  # check if to extract tags from object name
  if $et {
    my Str $tagstr = $object-name;
    $tagstr ~~ s:s:i/ the || also || are || all || and || him || his ||
            hers? || mine || ours? || was || following || some || various ||
            see || most || much || many || about || you
            //;

    $tags = [ $arg-tags.Slip,
              $tagstr.split(/ [\s || <punct> || \d]+ /).List.Slip,
              $prev-tags.Slip
            ];
  }

  else {
    $tags = [ $arg-tags.Slip, $prev-tags.Slip];
  }

  # Filter tags shorter than 3 chars, lowercase convert, remove
  # doubles then sort
  my @tlist = $tags.grep(/^...+/)>>.lc.unique.sort.List;
  $tags = [$tags.grep(/^...+/)>>.lc.unique.sort.List.Slip];

  # remove any tags
  for @$drop-tags -> $t {
    if my $index = $tags.first( $t, :k) {
      $tags.splice( $index, 1);
    }
  }

  # save new set of tags
  $udata<tags> = $tags;
  $object.set-user-metadata($udata);
}
