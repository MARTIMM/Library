use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use GTK::Glade::Native::Glib::GList;

use GTK::Glade::Native::Gtk::Entry;
use GTK::Glade::Native::Gtk::Widget;
use GTK::Glade::Native::Gtk::Checkbutton;
use GTK::Glade::Native::Gtk::Togglebutton;
use GTK::Glade::Native::Gtk::Grid;
use GTK::Glade::Native::Gtk::Label;
use GTK::Glade::Native::Gtk::Container;
use GTK::Glade::Native::Gtk::Listbox;

use Library::Tools;
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
  submethod BUILD ( Int:D :$!filter-type, GtkWidget:D :$!list-box ) {

    if $!filter-type ~~ SkipFilter {
      $!filter-list = Library::MetaConfig::SkipDataList.new;
    }

    elsif $!filter-type ~~ TagFilter {
      $!filter-list = Library::MetaConfig::TagFilterList.new;
    }

    else {
      die X::Library.new(:message("Unknown filter type $!filter-type"));
    }
  }

  #-----------------------------------------------------------------------------
  method clean-filter-list ( ) {

    my Array $list = $!filter-list.get-filter;

    loop {
      # Keep the index 0, entries will shift up after removal
      my GtkWidget $lb-entry = gtk_list_box_get_row_at_index( $!list-box, 0);
      last unless ?$lb-entry;
      gtk_widget_destroy($lb-entry);
    }
  }

  #-----------------------------------------------------------------------------
  method load-filter-list ( ) {

    my Array $list = $!filter-list.get-filter;

    for @$list -> $item-text {
      my GtkWidget $label = gtk_label_new($item-text);
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
  # Add a text from a text entry to the filter list
  method add-filter-item ( GtkWidget:D $entry ) {

    my Str $text = gtk_entry_get_text($entry);
    return unless ?$text;

    $!filter-list.set-filter( ($text,), :!drop);

    # Clear entry and refresh filter list
    gtk_entry_set_text( $entry, '');
    self.clean-filter-list;
    self.load-filter-list;
  }

  #-----------------------------------------------------------------------------
  # Remove entries from the list when the checkbutton before it is checked
  method delete-filter-items ( ) {

    my Array $delete-list = [];

    my $index = 0;
    loop {
      my GtkWidget $lb-entry = gtk_list_box_get_row_at_index(
        $!list-box, $index
      );

      last unless ?$lb-entry;
      $index++;

      my $children = gtk_container_get_children($lb-entry);
      my $grid = g_list_nth_data( $children, 0);
      my GtkWidget $check-box = gtk_grid_get_child_at( $grid, 0, 0);

      my Bool $checked = ? gtk_toggle_button_get_active($check-box);
      if $checked {

        my GtkWidget $label = gtk_grid_get_child_at( $grid, 1, 0);
        $delete-list.push: gtk_label_get_text($label);
      }
    }

    if ?$delete-list {
      $!filter-list.set-filter( @$delete-list, :drop);
      self.clean-filter-list;
      self.load-filter-list;
    }
  }
}
