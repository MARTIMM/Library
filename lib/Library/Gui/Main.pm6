use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use GTK::Glade;
use GTK::Glade::Engine;
#use GTK::Glade::NativeGtk :ALL;
#use GTK::Glade::Native::Gtk;
#use GTK::Glade::Native::Gtk::Enums;
use GTK::Glade::Native::Gtk::Main;
use GTK::Glade::Native::Gtk::Widget;
use GTK::Glade::Native::Gtk::Dialog;
use GTK::Glade::Native::Gtk::Image;
#use GTK::Glade::Native::Gtk::Checkbutton;
#use GTK::Glade::Native::Gtk::Grid;
#use GTK::Glade::Native::Gtk::Entry;
#use GTK::Glade::Native::Gtk::Container;
#use GTK::Glade::Native::Gtk::Listbox;

use Library::Tools;
use Library::Gui::FilterList;

#-------------------------------------------------------------------------------
class Gui::Main is GTK::Glade::Engine {

  has Str $!id-list = 'library-id-0000000000';

  #-----------------------------------------------------------------------------
  #submethod BUILD ( ) { }

  #-----------------------------------------------------------------------------
  # Realize event of tagsDialog or skipDialog
  # The realize event is fired when dialog is run. Object has name of listbox.
  method filter-dialog-realized ( :$widget, :$data, :$object ) {
    self.refresh-filter-list( :$widget, :$data, :$object );
  }

  #-----------------------------------------------------------------------------
  # Click event of refreshTagListBttn refreshSkipListBttn
  method refresh-filter-list ( :$widget, :$data, :$object ) {

    my Library::Gui::FilterList $filter-list;

    # test object for the listbox name to init the proper filter list
    if $object eq 'tagFilterListBox' {
      $filter-list .= new(
        :filter-type(TagFilter),
        :list-box(self.glade-get-widget($object))
      );
    }

    elsif $object eq 'skipDataListBox' {

      $filter-list .= new(
        :filter-type(SkipFilter),
        :list-box(self.glade-get-widget($object))
      );
    }

    else {
      die X::Library.new(:message("unknown listbox name"));
    }

    $filter-list.clean-filter-list;
    $filter-list.load-filter-list;
  }

  #-----------------------------------------------------------------------------
  method add-filter-item ( :$widget, :$data, :$object ) {

    my Library::Gui::FilterList $filter-list;
    my GtkWidget $input-entry;

    # test object for the listbox name to init the proper filter list
    if $object eq 'tagFilterListBox' {
      $filter-list .= new(
        :filter-type(TagFilter),
        :list-box(self.glade-get-widget($object))
      );

      $input-entry = self.glade-get-widget('inputTagFilterItemText');
    }

    elsif $object eq 'skipDataListBox' {

      $filter-list .= new(
        :filter-type(SkipFilter),
        :list-box(self.glade-get-widget($object))
      );

      $input-entry = self.glade-get-widget('inputSkipFilterItemText');
    }

    else {
      die X::Library.new(:message("unknown listbox name"));
    }

    $filter-list.add-filter-item($input-entry);
  }

  #-----------------------------------------------------------------------------
  method delete-filter-items ( :$widget, :$data, :$object ) {

    my Library::Gui::FilterList $filter-list;

    # test object for the listbox name to init the proper filter list
    if $object eq 'tagFilterListBox' {
      $filter-list .= new(
        :filter-type(TagFilter),
        :list-box(self.glade-get-widget($object))
      );
    }

    elsif $object eq 'skipDataListBox' {

      $filter-list .= new(
        :filter-type(SkipFilter),
        :list-box(self.glade-get-widget($object))
      );
    }

    else {
      die X::Library.new(:message("unknown listbox name"));
    }

    $filter-list.delete-filter-items;
  }

  #-----------------------------------------------------------------------------
  method exit-program ( :$widget, :$data, :$object ) {

    gtk_main_quit();
  }

  #-----------------------------------------------------------------------------
  # object is set to the id of the dialog to show
  method show-dialog ( :$widget, :$data, :$object ) {

    my GtkWidget $dialog = self.glade-get-widget($object);
    gtk_dialog_run($dialog);
  }

  #-----------------------------------------------------------------------------
  # object is set to the id of the dialog to close
  method hide-dialog ( :$widget, :$data, :$object ) {
    my GtkWidget $dialog = self.glade-get-widget($object);
    gtk_widget_hide($dialog);
  }

  #-----------------------------------------------------------------------------
  method show-about-dialog ( :$widget, :$data, :$object ) {

    my GtkWidget $dialog = self.glade-get-widget('aboutDialog');
    my GtkWidget $logo = gtk_image_new_from_file(
      %?RESOURCES<library-logo.png>.Str
    );

    my $pixbuf = gtk_image_get_pixbuf($logo);
    gtk_about_dialog_set_logo( $dialog, $pixbuf);

    gtk_dialog_run($dialog);
    gtk_widget_hide($dialog);
  }
}
