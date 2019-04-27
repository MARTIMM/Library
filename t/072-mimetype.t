use v6;
use lib 't';

use Test;
use Test-support;

use Library;
use Library::MetaConfig::Mimetype;

use MongoDB;
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

#initialize-library(:refine-key<u1>);
initialize-library;

#-------------------------------------------------------------------------------
subtest 'Install mimetypes', {

  my Library::MetaConfig::Mimetype $m .= new;
  $m.install-mimetypes( :!check-all, :one-entry);

  my BSON::Document $r =
     $m.get-mimetype(:mimetype<application/1d-interleaved-parityfec>);
  is $r<_id>, "application/1d-interleaved-parityfec", "found mimetype $r<_id>";
  is $r<type>, "application", "found its type $r<type>";
  is $r<subtype>, "1d-interleaved-parityfec", "found its subtype $r<subtype>";
  is-deeply $r<exts>, [], "there are no extensions";
}

#-------------------------------------------------------------------------------
subtest 'add mimetypes', {

  # add existing mime
  my Library::MetaConfig::Mimetype $m .= new;
  my BSON::Document $doc = $m.add-mimetype(
    "application/1d-interleaved-parityfec"
  );

  nok ?$doc,
      "mimetype 'application/1d-interleaved-parityfec' already in collection";

  my BSON::Document $r = $m.get-mimetype(:mimetype<application/A2l>);
  nok ?$r, "mimetype 'application/A2l' not found";

  ok ?$m.add-mimetype(
    "application/x-myprog", :extensions<mprg,mprl>, :exec('/tmp/myprg %f')
  ).defined, "application/x-myprog added to mimes";

  $r = $m.get-mimetype(:mimetype<application/x-myprog>);
  is $r<_id>, "application/x-myprog", "found application/x-myprog";
  is $r<type>, "application", "found its type";
  is $r<subtype>, "x-myprog", "found its subtype";
  is-deeply $r<exts>, [<mprg mprl>], "found 2 extensions";
  is $r<exec>, '/tmp/myprg %f', 'exec field set';
}

#-------------------------------------------------------------------------------
subtest 'modify mimetypes', {

  my Library::MetaConfig::Mimetype $m .= new;

  is $m.modify-mimetype(
    "application/x-myprog", :extensions<mprg1,mprl1>, :exec('')
  )<ok>, 1e0, "application/x-myprog added to mimes";

  my BSON::Document $r = $m.get-mimetype(:mimetype<application/x-myprog>);
  is-deeply $r<exts>, [<mprg1 mprl1>], "extensions modified";
  is $r<exec>, '', 'exec field reset';

}

#-------------------------------------------------------------------------------
subtest 'remove mimetypes', {

  my Library::MetaConfig::Mimetype $m .= new;

  is $m.remove-mimetype("application/x-myprog")<ok>, 1e0,
      "remove application/x-myprog";

  my BSON::Document $r = $m.get-mimetype(:mimetype<application/x-myprog>);
  nok ?$r, "mimetype 'application/x-myprog' is deleted";
  $r = $m.get-mimetype(:extension<mprg1>);
  nok ?$r, "extension 'mprg1' is deleted";
  $r = $m.get-mimetype(:extension<mprl1>);
  nok ?$r, "extension 'mprl1' is deleted";
}

#-------------------------------------------------------------------------------
done-testing;

unlink $dir ~ '/client-configuration.toml';
unlink $dir ~ '/meta072.log';
rmdir $dir;
