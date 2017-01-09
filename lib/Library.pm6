use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB::Client;
use Library::Configuration;

#-------------------------------------------------------------------------------
our $lib-cfg is export;
our $client is export;

#-------------------------------------------------------------------------------
sub initialize-library ( Str :$library-config ) is export {

  $lib-cfg = Library::Configuration.new(:$library-config);
  $client = MongoDB::Client.new(:uri($lib-cfg.config<uri>));
}

