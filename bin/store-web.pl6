#!/usr/bin/env perl6

use v6;

use Library;
use Library::Metadata::Database;
use Library::Config::TagsList;
use Library::Config::SkipList;
use Library::Metadata::Object::File;
use Library::Metadata::Object::Directory;
use GraphQL::Html;

use MongoDB;
use BSON::Document;
#use IO::Notification::Recursive;

#------------------------------------------------------------------------------
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

# set config file if it does not exist
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


# Allow switches after positionals. Pinched from the old panda program. Now it
# is possible to make the script files executable with the path of this program.
#say "Args: ", @*ARGS;
@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);
#say "MArgs: ", @*ARGS;

#------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
multi sub MAIN ( Str:D $uri ) {

  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));
  $gh.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $idx: Int) {
        linkList( idx: $idx, count: 3, withImage: true) {
          href
          imageList {
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%(:idx(0))));
#  diag "Result: " ~ $result.perl();

  is $result<data><linkList>[2]<href>,

}
