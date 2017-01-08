use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use MongoDB::Client;
use Library::Configuration;

#-------------------------------------------------------------------------------
our $library-config is export = Library::Configuration.new
    unless ?$library-config;

our $client = MongoDB::Client.new( :uri($library-config.config<uri>) )
    unless $client;


