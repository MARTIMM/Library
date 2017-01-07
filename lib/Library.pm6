use v6.c;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use Library::Configuration;

unit package Library:ver<0.3.0>;

our $cfg = from-toml(:file<xt/t/t.toml>);

our $client = MongoDB::Client.new(
  :uri("mongod://$cfg<server-name>:$sfg<$server-port>")
);


