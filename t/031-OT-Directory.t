use v6;
use Test;

use Library;
use Library::Metadata::Object::Directory;
use BSON::Document;

#-------------------------------------------------------------------------------
subtest 'OT File', {

  my Library::Metadata::Object::Directory $dir;
  
  $dir .= new( :object<lib/Library>, :type(OT-Directory));
  my BSON::Document $d = $dir.meta;
  is $d<object-name>, 'Library', $d<object-name>;
  like $d<object-path>, /:s lib $/, $d<object-path>;
  ok $d<object-exists>, 'object exists';

  say $d.perl;

  $dir .= new( :object<lib/Library/no-dir>, :type(OT-Directory));
  $d = $dir.meta;
  is $d<object-name>, 'no-dir', $d<object-name>;
  like $d<object-path>, /:s Library $/, $d<object-path>;
  ok !$d<object-exists>, 'object does not exist';

  say $d.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);
