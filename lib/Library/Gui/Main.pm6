use v6;

use GTK::Glade;
#use GTK::Glade::NativeGtk :ALL;
#use GTK::Glade::Native::Gtk;
use GTK::Glade::Native::Gtk::Main;
use GTK::Glade::Native::Gtk::Enums;
use GTK::Glade::Native::Gtk::Widget;
use GTK::Glade::Native::Gtk::Dialog;
use GTK::Glade::Native::Gtk::Checkbutton;
use GTK::Glade::Native::Gtk::Grid;
use GTK::Glade::Native::Gtk::Entry;
use GTK::Glade::Native::Gtk::Container;
use GTK::Glade::Native::Gtk::Listbox;

use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;
#-------------------------------------------------------------------------------
unit class Library::Gui::Main:auth<github:MARTIMM> is GTK::Glade::Engine;

has Library::MetaConfig::TagFilterList $!tag-filter-list;
has Library::MetaConfig::SkipDataList $!skip-data-list;
#has Str $!id-list = 'library-id-0000000000';

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  $!tag-filter-list .= new;
  $!skip-data-list .= new;
}

#-------------------------------------------------------------------------------
method refresh-tagfilter-list ( :$widget, :$data, :$object ) {

  my Array $list = $!tag-filter-list.get-tag-filter;
  my GtkWidget $list-box = self.glade-get-widget('tagFilterListBox');

  # Empty list first
  loop {
    # Keep the index 0, entries will shift up after removal
    my GtkWidget $entry = gtk_list_box_get_row_at_index( $list-box, 0);
    last unless ?$entry;
    gtk_widget_destroy($entry);
  }

  # Fill it again
  for @$list -> $tag {
    my GtkWidget $textentry = gtk_entry_new();
    gtk_entry_set_text( $textentry, $tag);
    gtk_widget_set_visible( $textentry, True);

    my GtkWidget $check = gtk_check_button_new_with_label('');
    gtk_widget_set_visible( $check, True);

    my GtkWidget $grid = gtk_grid_new();
    gtk_widget_set_visible( $grid, True);
    gtk_grid_attach( $grid, $textentry, 0, 0, 1, 1);
    gtk_grid_attach( $grid, $check, 1, 0, 1, 1);

    gtk_container_add( $list-box, $grid);
  }
}

#-------------------------------------------------------------------------------
method refresh-skipdata-list ( :$widget, :$data, :$object ) {

  my Array $list = $!skip-data-list.get-skip-filter;
  my GtkWidget $list-box = self.glade-get-widget('skipDataListBox');

  # Empty list first
  loop {
    # Keep the index 0, entries will shift up after removal
    my GtkWidget $entry = gtk_list_box_get_row_at_index( $list-box, 0);
    last unless ?$entry;
    gtk_widget_destroy($entry);
  }

  # Fill it again
  for @$list -> $skip {
    my GtkWidget $textentry = gtk_entry_new();
    gtk_entry_set_text( $textentry, $skip);
    gtk_widget_set_visible( $textentry, True);

    my GtkWidget $check = gtk_check_button_new_with_label('');
    gtk_widget_set_visible( $check, True);

    my GtkWidget $grid = gtk_grid_new();
    gtk_widget_set_visible( $grid, True);
    gtk_grid_attach( $grid, $textentry, 0, 0, 1, 1);
    gtk_grid_attach( $grid, $check, 1, 0, 1, 1);
    gtk_container_add( $list-box, $grid);
  }
}

#-------------------------------------------------------------------------------
method exit-program ( :$widget, :$data, :$object ) {

  gtk_main_quit();
}

#-------------------------------------------------------------------------------
method show-about-dialog ( :$widget, :$data, :$object ) {

  my GtkWidget $dialog = self.glade-get-widget('aboutDialog');
  gtk_dialog_run($dialog);
  #my $r = gtk_dialog_run($dialog);
  #note "Pressed: ", GtkResponseType($r);
  gtk_widget_hide($dialog);
}
