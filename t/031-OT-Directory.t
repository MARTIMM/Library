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
  is $d<name>, 'Library', $d<name>;
  like $d<path>, /:s lib $/, $d<path>;
  ok $d<exists>, 'object exists';

  say $d.perl;

  $dir .= new( :object<lib/Library/no-dir>, :type(OT-Directory));
  $d = $dir.meta;
  is $d<name>, 'no-dir', $d<name>;
  like $d<path>, /:s Library $/, $d<path>;
  ok !$d<exists>, 'object does not exist';

  say $d.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);
