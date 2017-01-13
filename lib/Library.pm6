use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB::Client;
use Library::Configuration;

#-------------------------------------------------------------------------------
enum ObjectType is export <OT-File OT-Directory>;

our $lib-cfg is export;
our $client is export;

#-------------------------------------------------------------------------------
sub initialize-library ( Str :$library-config ) is export {

  $lib-cfg = Nil if $lib-cfg.defined;
  $lib-cfg = Library::Configuration.new(:$library-config);

  $client.cleanup if $client.defined;
  $client = Nil;
  $client = MongoDB::Client.new(:uri($lib-cfg.config<uri>));
}

