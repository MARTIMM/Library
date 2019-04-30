#!/usr/bin/env perl6

use v6;
use lib '/home/marcel/Languages/Perl6/Projects/gtk-glade/lib',
        '/home/marcel/Languages/Perl6/Projects/gtk-v3/lib',
        '/home/marcel/Languages/Perl6/Projects/mongo-perl6-driver/lib';
#use lib '/home/marcel/Languages/Perl6/Projects/gtk-v3/lib';

# Version of library
my Version $*version = v0.13.3;
my Bool $*debug = False;


use Library;
use Library::Tools;
use Library::Gui::Main;
use Library::Gui::FilterList;

use GTK::V3::Gtk::GtkButton;
use GTK::Glade;

#-------------------------------------------------------------------------------
#initialize-library(:refine-key<marcel>);
initialize-library();

#-------------------------------------------------------------------------------
sub MAIN ( Bool :$debug = False ) {

  my Library::Tools $tools .= new;
  my Str $ui-file = $tools.get-resource(:which<library.glade>);

  my GTK::Glade $gui .= new;
  $gui.add-gui-file($ui-file);
  $gui.add-engine(Library::Gui::Main.new);
  $gui.add-engine(Library::Gui::FilterList.new);

  GTK::V3::Gtk::GtkButton.new(:empty).debug(:on) if $debug;
  $*debug = $debug;

  $gui.run;
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
