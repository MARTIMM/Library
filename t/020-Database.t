use v6;
use Data::Dump::Tree;
use Test;

use Library;
use Library::Database;
use Library::Metadata::Database;
use BSON::Document;

#-------------------------------------------------------------------------------
subtest 'Database', {

  # setup config directory
  mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
  %*ENV<LIBRARY-CONFIG> = 't/Lib4';
  my Str $filename = 't/Lib4/config.toml';
  spurt( $filename, Q:to/EOCFG/);

    # MongoDB server connection
    uri         = 'mongodb://localhost:27017'

    #database    = 'test'

    [ collection ]
    #  meta-data = 'test-meta'

    EOCFG

  initialize-library();


  # define class doing database work
  class Mdb does Library::Database {

    submethod BUILD ( ) {

      my Library::Configuration $lcg := $Library::lib-cfg;

      $lcg.config<database> = 'xyz' unless ?$lcg.config<database>;
      $lcg.config<collection><meta-data> = 'meta'
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
}

#-------------------------------------------------------------------------------
subtest 'Metadata database', {

  # setup config directory
  mkdir 't/Lib4', 0o700 unless 't/Lib4'.IO ~~ :d;
  %*ENV<LIBRARY-CONFIG> = 't/Lib4';
  my Str $filename = 't/Lib4/config.toml';
  spurt( $filename, Q:to/EOCFG/);

    # MongoDB server connection
    uri         = 'mongodb://localhost:27017'

    database    = 'test'

    [ collection ]
      meta-data = 'test-meta'

    EOCFG

  initialize-library();

  # insert a document
  my Library::Metadata::Database $meta .= new;
  my BSON::Document $doc = $meta.insert: [ (
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

  say $doc.perl;
  is $doc<ok>, 1, 'delete ok';
}

#-------------------------------------------------------------------------------
#cleanup
done-testing;

unlink 't/Lib4/config.toml';
rmdir 't/Lib4';

exit(0);

