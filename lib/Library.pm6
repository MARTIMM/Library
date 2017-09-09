use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB::Client;
use Library::Configuration;

#------------------------------------------------------------------------------
# Values are Str so they can be used as type value in a mongodb document
enum ObjectType is export <<
  :OT-File('File') :OT-Directory('Directory')
  :OT-Program('Program') :OT-User('User') :OT-Web('Web')
>>;

our $lib-cfg is export;
our $client is export;

#------------------------------------------------------------------------------
sub initialize-library ( ) is export {

  $lib-cfg = Nil if $lib-cfg.defined;
  $lib-cfg = Library::Configuration.new;

  $client.cleanup if $client.defined;
  $client = MongoDB::Client.new(:uri($lib-cfg.config<uri>));
}
