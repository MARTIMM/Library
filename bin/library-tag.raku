#!/usr/bin/env perl6

use v6;

use Library;
use Library::MetaConfig::TagFilterList;

#-------------------------------------------------------------------------------
initialize-library();

#-------------------------------------------------------------------------------
# Allow switches after positionals. Pinched from the old panda program. Now it
# is possible to make the script files executable with the path of this program.

@*ARGS = |@*ARGS.grep(/^ '-'/), |@*ARGS.grep(/^ <-[-]>/);

#-------------------------------------------------------------------------------
# Store a list of tags in the configuration collection
sub MAIN ( *@filter-list, Bool :$drop = False, Bool :$list = False ) {

  # access config collection
  my Library::MetaConfig::TagFilterList $c .= new;
  $c.set-filter( @filter-list, :$drop) if ?@filter-list;

  my Array $filter-list = $c.get-filter;
  note "\n  [ '", $filter-list.join("', '"), "']\n" if $list and ?$filter-list;
}
