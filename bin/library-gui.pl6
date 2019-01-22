#!/usr/bin/env perl6

use v6;
use lib "../gtk-glade/lib";
use GTK::Glade;
use Library;
use Library::Gui::Main;
use Library::Gui::Tools;

#-------------------------------------------------------------------------------
initialize-library();

#-------------------------------------------------------------------------------
sub MAIN ( ) {

  my Library::Gui::Tools $tools .= new;
  my Library::Gui::Main $main-engine .= new;

  my Str $ui-file = $tools.glade-file(:which<library.glade>);
  my GTK::Glade $gui .= new( :$ui-file, :engine($main-engine));
}

#-------------------------------------------------------------------------------
sub USAGE ( ) {

  note Q:qq:to/EOUSAGE/;

    Usage:
      $*PROGRAM [<options>] <arguments>

    Options:

    Arguments:

  EOUSAGE
}
