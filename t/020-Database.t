use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::Database;
use BSON::Document;

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');

#-------------------------------------------------------------------------------
subtest 'Database', {

  # setup config directory
  mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
  %*ENV<LIBRARY-CONFIG> = 't/Lib4';
  my Str $filename = 't/Lib4/config.toml';
  spurt( $filename, Q:qq:to/EOCFG/);

    # MongoDB server connection
    uri         = "mongodb://localhost:$p1"

    EOCFG

  initialize-library();


  # Define class doing database work. This class set database to 'xyz' and
  # collection to 'abc'.
  class Mdb does Library::Database {

    submethod BUILD ( ) {

      my Library::Configuration $lcg := $Library::lib-cfg;

      $lcg.config<database> = 'xyz' unless ?$lcg.config<database>;
      $lcg.config<collection><meta-data> = 'abc'
        unless ?$lcg.config<meta-data>;
      $lcg.save;

      self.init( :database-key<database>, :collection-key<meta-data>);
    }
  }

  # instantiate
  my Mdb $mdb .= new;
  isa-ok $mdb, 'Mdb';

  # insert a document
  my BSON::Document $doc = $mdb.insert: [ (
      object-name => 'Library',
      object-type => 'Project',
      location => '/home/marcel/Languages/Perl6/Projects/Library'
    ),
  ];

  is $doc<ok>, 1, 'insert ok';

  # delete database
  $doc = $mdb.drop-database;

  say $doc.perl;
  is $doc<ok>, 1, 'database dropped ok';




  # setup another config
  spurt( $filename, Q:qq:to/EOCFG/);

    # MongoDB server connection
    uri         = "mongodb://localhost:$p1"

    EOCFG

  initialize-library();

  # instantiate
  my Mdb $meta .= new;

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
  is $doc<ok>, 1, 'insert ok';


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
  $doc = $meta.count;
  is $doc<ok>, 1, 'count ok';
  ok $doc<n> >= 1, 'at least 1';
  say $doc.perl;

  # count only f1 == v1 records
  $doc = $meta.count: ( f1 => 'v1', );
  is $doc<ok>, 1, 'count ok';
  ok $doc<n> >= 1, 'at least 1';
  say $doc.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

unlink 't/Lib4/config.toml';
rmdir 't/Lib4';

exit(0);

