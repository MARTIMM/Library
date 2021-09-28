use v6.d;
#use lib '../mongo-perl6-driver/lib';
use Test;

use Library::DB::Client;
use BSON::Document;
use QA::Types;

#-------------------------------------------------------------------------------
constant library-id = 'io.github.martimm.library';

given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfg-root(library-id);
#  note "Dirs: ", .list-dirs;
}


#-------------------------------------------------------------------------------
my Library::DB::Client $db-client .= new;
$db-client.connect;

my Str $user-collection-key = 'test-coll';
my BSON::Document $res;
my BSON::Document $doc .= new: (
  :abc<def>,
  :pqr(BSON::Document.new: ( :t1<xyz>, :t2(10))),
  xyz => [ |<a b c d e f>],
);


$db-client.insert( [$doc,], :lib);
$db-client.find( BSON::Document.new(('pqr.t1' => 'xyz')), :lib);
while $res = $db-client.get-document {
  is $res<abc>, 'def', 'entry abc found';
  is $res<pqr><t2>, 10, 'entry pqr.t2 found';
}
$db-client.drop-collection( :$user-collection-key, :lib);


$db-client.insert( [$doc,], :$user-collection-key, :!lib);
$db-client.find(
  BSON::Document.new(('pqr.t1' => 'xyz')), :$user-collection-key, :!lib
);

while $res = $db-client.get-document {
  is $res<abc>, 'def', 'entry abc found';
  is $res<pqr><t2>, 10, 'entry pqr.t2 found';
}

$db-client.drop-collection( :$user-collection-key, :!lib);


$db-client.cleanup;

#-------------------------------------------------------------------------------
done-testing;
