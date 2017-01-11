use v6;
use Test;

use Library;
use Library::Metadata::Object::File;
use BSON::Document;

#-------------------------------------------------------------------------------
subtest 'OT File', {

  my Library::Metadata::Object::File $f;
  
  $f .= new( :object<t/030-OT-File.t>, :type(OT-File));
  say $f.meta.perl;

  $f .= new( :object<t/other-file.t>, :type(OT-File));
  say $f.meta.perl;
}

#-------------------------------------------------------------------------------
#cleanup
done-testing;

#unlink 't/Lib4/config.toml';
#rmdir 't/Lib4';

exit(0);
