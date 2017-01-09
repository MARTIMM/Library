use v6;
use Data::Dump::Tree;
use Test;

use Library;
use Library::Metadata::Database;
use BSON::Document;

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
  my BSON::Document $doc = $meta.insert( (
      object-name => 'Library',
      object-type => 'Project',
      location => '/home/marcel/Languages/Perl6/Projects/Library'
    ),
  );

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
  $doc = $meta.delete: ( q => ( object-type => 'Project',), limit => 1,),;

  say $doc.perl;
  is $doc<ok>, 1, 'insert ok';
}

#-------------------------------------------------------------------------------
#cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);

