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
  is $d<name>, '030-OT-File.t', $d<name>;
  is $d<extension>, 't', $d<extension>;
  like $d<path>, /:s t $/, $d<path>;
  ok $d<exists>, 'object exists';
  ok $d<content-sha1>, 'sha calculated on content';

#  say $d.perl;

  $f .= new( :object<t/other-file.t>, :type(OT-File));
  $d = $f.meta;
  is $d<name>, 'other-file.t', $d<name>;
  like $d<path>, /:s t $/, $d<path>;
  ok !$d<exists>, 'object does not exist';
  ok !$d<content-sha1>, 'no sha on content';

#  say $d.perl;
}

#-------------------------------------------------------------------------------
# cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);
