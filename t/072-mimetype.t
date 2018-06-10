use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::MetaConfig::Mimetype;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::Cursor;

use BSON::Document;

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;
my Int $p1 = $ts.server-control.get-port-number('s1');
my Str $db-name = 'meta072';
my Str $cl-name = 'mimetypes';
my Str $dir = 't/meta072';

#-------------------------------------------------------------------------------
# setup config directory
mkdir $dir, 0o700 unless $dir.IO ~~ :d;
%*ENV<LIBRARY_CONFIG> = $dir;
my Str $filename = $dir ~ '/client-configuration.toml';
spurt( $filename, Q:qq:to/EOCFG/);

    [ connection ]
      server      = "localhost"
      port        = $p1

    [ library ]
      root-db         = "Library"
      user-db         = "$db-name"
      logfile         = "meta072.log"
      loglevelfile    = "Info"
      loglevelscreen  = "Info"

    [ library.collections ]
      meta-data   = "meta072Data"
    #  meta-config = "$cl-name"

    [ library.collections.root ]
      mimetypes   = "Mimetypes"

    EOCFG

#initialize-library(:user-key<u1>);
initialize-library;

my MongoDB::Client $client := $Library::client;
my MongoDB::Database $database = $client.database( $db-name, :root);
$database.run-command: (dropDatabase => 1,);
my MongoDB::Collection $cl-cfg = $database.collection( $cl-name, :root);
my MongoDB::Cursor $cu;

#-------------------------------------------------------------------------------
subtest 'Install mimetypes', {

  my Library::MetaConfig::Mimetype $m .= new;
  $m.install-mimetypes(:!check-all);

  my BSON::Document $r = $m.get-mimetype(:mimetype<image/fits>);
  is $r<_id>, "image/fits", "found image/fits";
  is $r<type>, "image", "found its type";
  is $r<subtype>, "fits", "found its subtype";
  is-deeply $r<exts>, [<fit fits fts>], "found 3 extentions";
}

#-------------------------------------------------------------------------------
subtest 'add mimetypes', {

  # add existing mime
  my Library::MetaConfig::Mimetype $m .= new;
  ok $m.add-mimetype(
    "application/A2l", :extensions<.a2l>  #, :exec('/usr/bin/ffplay %f')
  ), "application/A2l already in mimetype collection";

  my BSON::Document $r = $m.get-mimetype(:mimetype<application/A2l>);
  is $r<_id>, "application/A2l", "found application/A2l";
  is $r<type>, "application", "found its type";
  is $r<subtype>, "A2l", "found its subtype";
  is-deeply $r<exts>, [<a2l>], "found 1 extention";

  nok $m.add-mimetype(
    "application/x-myprog", :extensions<mprg,mprl>, :exec('/tmp/myprg %f')
  ), "application/x-myprog added to mimes";
}

#-------------------------------------------------------------------------------
done-testing;

#$database.run-command: (dropDatabase => 1,);
$client.cleanup;

#unlink $dir ~ '/client-configuration.toml';
#unlink $dir ~ '/meta072.log';
#rmdir $dir;
