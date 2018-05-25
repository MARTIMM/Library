use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Storage;
use MongoDB;
use BSON::Document;

#------------------------------------------------------------------------------
#drop-send-to('mongodb');
#drop-send-to('screen');
modify-send-to( 'screen', :level(MongoDB::MdbLoglevels::Info));
info-message("Test $?FILE start");

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');

#-------------------------------------------------------------------------------
subtest 'Database', {

  # setup config directory
  mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
  %*ENV<LIBRARY_CONFIG> = 't/Lib4';
  my Str $filename = 't/Lib4/client-configuration.toml';
  spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]

      # MongoDB server connection
      server      = "localhost"
      port        = "$p1"

    [ library ]
      root-db     = "Library"
      user-db     = "MyLibrary"

    [ library.collections ]
      meta-data   = "MyData"

    EOCFG

  initialize-library;
  my Library::Configuration $lcg := $Library::lib-cfg;

  # instantiate
  my Library::Storage $mdb .= new(:collection-key<meta-data>);

  # insert a document
  my BSON::Document $doc = $mdb.insert: [ (
      object-name => 'Library',
      object-type => 'Project',
      location => ~$*CWD
    ),
  ];

  is $doc<ok>, 1, 'insert ok';

  # delete database
  $doc = $mdb.drop-database;

  diag $doc.perl;
  is $doc<ok>, 1, 'database dropped ok';




  # setup another config
  spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      # MongoDB server connection
      server      = "localhost"
      port        = "$p1"

    [ library ]
      root-db     = "Library"
      user-db     = "MyLibrary"

    [ library.collections ]
      meta-data   = "MyData"

    EOCFG

  initialize-library();

  # instantiate another database
  my Library::Storage $meta .= new(:collection-key<meta-data>);

  # insert a document
  $doc = $meta.insert: [ (
      object-name => 'Library',
      object-type => 'Project',
      location => '/home/marcel/Languages/Perl6/Projects/Library'
    ), (
      object-name => 'Semi-xml',
      object-type => 'Project',
      location => '/home/marcel/Languages/Perl6/Projects/Semi-xml'
    ),
  ];
  diag $doc.perl;
  is $doc<ok>, 1, 'insert ok';
  is $doc<n>, 2, 'two docs inserted';


  # update data
  $doc = $meta.update: [ (
      q => (object-name => 'Semi-xml',),
      u => ('$set' => (f1 => 'v1',),),
      upsert => True,
    ),
  ];
  is $doc<ok>, 1, 'update ok';


  # find document use all parameters of MongoDB::Collection.find()
  my $cursor = $meta.find(
    :criteria(object-type => 'Project',),
    :projection(_id => 0,)
  );

  while $cursor.fetch -> BSON::Document $document {
    is $document<object-type>, 'Project', 'object-type found';
  }


  # delete documents
  $doc = $meta.delete: [
    (q => ( object-name => 'Library',), limit => 1),
#    (q => ( object-type => 'Project',), limit => 0),
#    (q => ( location => '/home/marcel/Languages/Perl6/Projects/Library',), limit => 0),
  ];
  is $doc<ok>, 1, 'delete ok';


  # count all records
  $doc = $meta.count: ();
  is $doc<ok>, 1, 'count ok';
  ok $doc<n> >= 1, 'at least 1';

  # count only f1 == v1 records
  $doc = $meta.count: ( f1 => 'v1', );
  is $doc<ok>, 1, 'count ok';
  ok $doc<n> >= 1, 'at least 1';
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/client-configuration.toml';
rmdir 't/Lib4';

exit(0);
