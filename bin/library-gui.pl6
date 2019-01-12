#!/usr/bin/env perl6

use v6;
use lib "../gtk-glade/lib";
use GTK::Glade;
use Library::Gui::Main;
use Library::Gui::Tools;

#-------------------------------------------------------------------------------
sub MAIN ( ) {

  my Library::Gui::Tools $tools .= new;
  my Library::Gui::Main $main-engine .= new;

  my Str $main-gui = $tools.glade-file(:which<library.glade>);
  my GTK::Glade $gui .= new( :ui-file($main-gui), :engine($main-engine));
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
