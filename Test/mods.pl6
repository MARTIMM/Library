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

use GTK::Glade;
use GTK::Glade::Engine;


use GTK::V3::Gtk::GtkMain;
use GTK::V3::Gtk::GtkWidget;
use GTK::V3::Gtk::GtkDialog;
use GTK::V3::Gtk::GtkAboutDialog;
use GTK::V3::Gtk::GtkImage;
use GTK::V3::Gtk::GtkListBox;
use GTK::V3::Gtk::GtkEntry;
use GTK::V3::Gtk::GtkFileChooserDialog;
use GTK::V3::Gtk::GtkFileChooser;

use GTK::V3::Glib::GSList;
#use GTK::V3::Glib::GObject;
#use GTK::V3::Glib::GInterface;

note "\nGlib: ", GTK::V3::Glib::.keys;
#note "\nGtk: ", GTK::V3::Gtk::.keys;
