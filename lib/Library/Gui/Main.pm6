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

use Library::Gui::FilterList;

#-------------------------------------------------------------------------------
class Gui::Main is GTK::Glade::Engine {

  has Str $!id-list = 'library-id-0000000000';

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {
  }

  #-----------------------------------------------------------------------------
  # the realize event is fired when dialog is run. Object has name of listbox.
  method filter-dialog-realized ( :$widget, :$data, :$object ) {
note "realize tag dialog";
    self.refresh-filter-list( :$widget, :$data, :$object );
  }

  #-----------------------------------------------------------------------------
  # click event of refreshTagListBttn
  method refresh-filter-list ( :$widget, :$data, :$object ) {

note "O: $object";
    my Library::Gui::FilterList $filter-list;

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
      die "unknown listbox name";
    }

    $filter-list.clean-filter-list;
    $filter-list.load-filter-list;
  }
#`{{
  #-----------------------------------------------------------------------------
  # click event of refreshTagListBttn
  method refresh-tagfilter-list ( :$widget, :$data, :$object ) {

    my Library::Gui::FilterList $tag-filter-list .= new(
      :filter-type(TagFilter),
      :list-box(self.glade-get-widget('tagFilterListBox'))
    );

    $tag-filter-list.clean-filter-list;
    $tag-filter-list.load-filter-list;
  }

  #-----------------------------------------------------------------------------
  # the realize event is fired when dialog is run.
  method skip-dialog-realized ( :$widget, :$data, :$object ) {
note "realize skip dialog";
    self.refresh-skipfilter-list( :$widget, :$data, :$object );
  }
}}
#`{{
  #-----------------------------------------------------------------------------
  # click event of refreshSkipListBttn
  method refresh-skipfilter-list ( :$widget, :$data, :$object ) {

    my Library::Gui::FilterList $skip-filter-list .= new(
      :filter-type(SkipFilter),
      :list-box(self.glade-get-widget('skipDataListBox'))
    );

    $skip-filter-list.clean-filter-list;
    $skip-filter-list.load-filter-list;
  }

  #-----------------------------------------------------------------------------
  method delete-tagfilter-items ( :$widget, :$data, :$object ) {
note "Delete marked tag items";

    my Library::Gui::FilterList $tag-filter-list .= new(
      :filter-type(TagFilter),
      :list-box(self.glade-get-widget('tagFilterListBox'))
    );

    $tag-filter-list.delete-filter-items;
  }
}}
  #-----------------------------------------------------------------------------
  method delete-skipfilter-items ( :$widget, :$data, :$object ) {
note "Delete marked skip items";
  }

  #-----------------------------------------------------------------------------
  method exit-program ( :$widget, :$data, :$object ) {

    gtk_main_quit();
  }

  #-----------------------------------------------------------------------------
  # object is set to the id of the dialog to show
  method show-dialog ( :$widget, :$data, :$object ) {
note "Show dialog";

    my GtkWidget $dialog = self.glade-get-widget($object);
note "Show dialog: ", $dialog;
    gtk_dialog_run($dialog);
  }

  #-----------------------------------------------------------------------------
  # object is set to the id of the dialog to close
  method hide-dialog ( :$widget, :$data, :$object ) {
note "Hide dialog: ", $data, ', ', $object;
    my GtkWidget $dialog = self.glade-get-widget($object);
    gtk_widget_hide($dialog);
  }

  #-----------------------------------------------------------------------------
  method show-about-dialog ( :$widget, :$data, :$object ) {

    my GtkWidget $dialog = self.glade-get-widget('aboutDialog');
note "R: ", %?RESOURCES<library-logo.png>.Str;
    my GtkWidget $logo = gtk_image_new_from_file(
      %?RESOURCES<library-logo.png>.Str
    );
note "W: ", $logo;
    my $pixbuf = gtk_image_get_pixbuf($logo);
note "P: ", $pixbuf;
    gtk_about_dialog_set_logo( $dialog, $pixbuf);
note "pixbuf set";

    gtk_dialog_run($dialog);
    gtk_widget_hide($dialog);
  }
}
