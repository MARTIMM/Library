use v6;
use Test;

use Library;
use Library::Metadata::Object::File;
use BSON::Document;

#-------------------------------------------------------------------------------
subtest 'OT File', {

  my Library::Metadata::Object::File $f;

  $f .= new( :object<t/030-OT-File.t>, :type(OT-File));
  my BSON::Document $d = $f.meta;
  is $d<object-name>, '030-OT-File.t', $d<object-name>;
  is $d<object-extension>, 't', $d<object-extension>;
  like $d<object-path>, /:s t $/, $d<object-path>;
  ok $d<object-exists>, 'object exists';
  ok $d<content-sha1>, 'sha calculated on content';

#  say $d.perl;

  $f .= new( :object<t/other-file.t>, :type(OT-File));
  $d = $f.meta;
  is $d<object-name>, 'other-file.t', $d<object-name>;
  like $d<object-path>, /:s t $/, $d<object-path>;
  ok !$d<object-exists>, 'object does not exist';
  ok !$d<content-sha1>, 'no sha on content';

#  say $d.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);
