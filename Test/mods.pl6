#!/usr/bin/env perl6

use v6;
#use lib '/home/marcel/Languages/Perl6/Projects/gtk-glade/lib',
#        '/home/marcel/Languages/Perl6/Projects/gtk-v3/lib';

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#`{{
}}
use Library::Tools;
use Library::Gui::FilterList;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;


use Gnome::Gtk3::Main;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::AboutDialog;
use Gnome::Gtk3::Image;
use Gnome::Gtk3::ListBox;
use Gnome::Gtk3::Entry;
use Gnome::Gtk3::FileChooserDialog;
use Gnome::Gtk3::FileChooser;

use Gnome::Glib::SList;
#use GTK::V3::Glib::GObject;
#use GTK::V3::Glib::GInterface;

note "\nGlib: ", GTK::V3::Glib::.keys;
#note "\nGtk: ", GTK::V3::Gtk::.keys;
