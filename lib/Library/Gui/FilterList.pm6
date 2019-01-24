use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#use GTK::Glade::Native::Gtk::Enums;
use GTK::Glade::Native::Gtk::Widget;
use GTK::Glade::Native::Gtk::Checkbutton;
use GTK::Glade::Native::Gtk::Grid;
use GTK::Glade::Native::Gtk::Label;
use GTK::Glade::Native::Gtk::Container;
use GTK::Glade::Native::Gtk::Listbox;

use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;

#-------------------------------------------------------------------------------
class Gui::FilterList {

  #-----------------------------------------------------------------------------
  enum FilterType is export < TagFilter SkipFilter >;

  has $!filter-list;
  has Int $!filter-type;
  has GtkWidget $!list-box;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Int:D :$!filter-type, GtkWidget:D :$!list-box ) { }

  #-----------------------------------------------------------------------------
  method clean-filter-list ( ) {

    my Array $list;

    if $!filter-type ~~ SkipFilter {
      $!filter-list = Library::MetaConfig::SkipDataList.new;
      $list = $!filter-list.get-skip-filter;
    }

    elsif $!filter-type ~~ TagFilter {
      $!filter-list = Library::MetaConfig::TagFilterList.new;
      $list = $!filter-list.get-tag-filter;
    }

    else {
      die "Unknown filter type $!filter-type";
    }

    loop {
      # Keep the index 0, entries will shift up after removal
      my GtkWidget $lb-entry = gtk_list_box_get_row_at_index( $!list-box, 0);
      last unless ?$lb-entry;
      gtk_widget_destroy($lb-entry);
    }
  }

  #-----------------------------------------------------------------------------
  method load-filter-list ( ) {

    my Array $list;

    if $!filter-type ~~ SkipFilter {
      $!filter-list = Library::MetaConfig::SkipDataList.new;
      $list = $!filter-list.get-skip-filter;
    }

    elsif $!filter-type ~~ TagFilter {
      $!filter-list = Library::MetaConfig::TagFilterList.new;
      $list = $!filter-list.get-tag-filter;
    }

    else {
      die "Unknown filter type $!filter-type";
    }

    for @$list -> $item-text {
      my GtkWidget $label = gtk_label_new($item-text);
      #gtk_label_set_text( $label, $item-text);
      gtk_widget_set_visible( $label, True);

      my GtkWidget $check = gtk_check_button_new_with_label('');
      gtk_widget_set_visible( $check, True);

      my GtkWidget $grid = gtk_grid_new();
      gtk_widget_set_visible( $grid, True);
      gtk_grid_attach( $grid, $check, 0, 0, 1, 1);
      gtk_grid_attach( $grid, $label, 1, 0, 1, 1);

      gtk_container_add( $!list-box, $grid);
    }
  }

  #-----------------------------------------------------------------------------
  method delete-filter-items ( ) {
return;
    if $!filter-type ~~ SkipFilter {
      $!filter-list = Library::MetaConfig::SkipDataList.new;
    }

    elsif $!filter-type ~~ TagFilter {
      $!filter-list = Library::MetaConfig::TagFilterList.new;
    }

    else {
      die "Unknown filter type $!filter-type";
    }

    my Array $delete-list;

    my $index = 0;
    loop {
      my GtkWidget $lb-entry = gtk_list_box_get_row_at_index( $!list-box, $index);
      last unless ?$lb-entry;
    }
  }
}
