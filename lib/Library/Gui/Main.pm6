use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use GTK::Glade;
use GTK::Glade::Engine;

use GTK::V3::Gtk::GtkMain;
use GTK::V3::Gtk::GtkWidget;
use GTK::V3::Gtk::GtkDialog;
use GTK::V3::Gtk::GtkAboutDialog;
use GTK::V3::Gtk::GtkImage;
use GTK::V3::Gtk::GtkListBox;

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
  method filter-dialog-realized ( |c ) {
    self.refresh-filter-list( |c );
  }

  #-----------------------------------------------------------------------------
  # Click event of refreshTagListBttn refreshSkipListBttn
  method refresh-filter-list ( :widget($dialog), Str :$target-widget-name ) {

    my Library::Gui::FilterList $filter-list;
    my GTK::V3::Gtk::GtkListBox $list-box;

    # test object for the listbox name to init the proper filter list
    if $target-widget-name eq 'tagFilterListBox' {
      $list-box .= new(:widget(self.glade-get-widget($target-widget-name)));
      $filter-list .= new( :filter-type(TagFilter), :$list-box);
    }

    elsif $target-widget-name eq 'skipDataListBox' {
      $list-box .= new(:widget(self.glade-get-widget($target-widget-name)));
      $filter-list .= new( :filter-type(SkipFilter), :$list-box);
    }

    else {
      die X::Library.new(:message("unknown listbox name"));
    }

    $filter-list.clean-filter-list;
    $filter-list.load-filter-list;
  }

  #-----------------------------------------------------------------------------
  method add-filter-item ( :widget($dialog), :$target-widget-name ) {

    my Library::Gui::FilterList $filter-list;
    my GTK::V3::Gtk::GtkEntry $input-entry;
    my GTK::V3::Gtk::GtkListBox $list-box;

    # test object for the listbox name to init the proper filter list
    if $target-widget-name eq 'tagFilterListBox' {
      $list-box .= new(:widget(self.glade-get-widget($target-widget-name)));
      $filter-list .= new( :filter-type(TagFilter), :$list-box);
      $input-entry .= new(
        :widget(self.glade-get-widget('inputTagFilterItemText'))
      );
    }

    elsif $target-widget-name eq 'skipDataListBox' {
      $list-box .= new(:widget(self.glade-get-widget($target-widget-name)));
      $filter-list .= new( :filter-type(SkipFilter), :$list-box);
      $input-entry .= new(
        :widget(self.glade-get-widget('inputSkipFilterItemText'))
      );
    }

    else {
      die X::Library.new(:message("unknown listbox name"));
    }

    $filter-list.add-filter-item($input-entry);
  }

  #-----------------------------------------------------------------------------
  method delete-filter-items ( :widget($button), :$target-widget-name ) {

    my Library::Gui::FilterList $filter-list;
    my GTK::V3::Gtk::GtkListBox $list-box;

    # test object for the listbox name to init the proper filter list
    if $target-widget-name eq 'tagFilterListBox' {
      $list-box .= new(:widget(self.glade-get-widget($target-widget-name)));
      $filter-list .= new( :filter-type(TagFilter), :$list-box);
    }

    elsif $target-widget-name eq 'skipDataListBox' {
      $list-box .= new(:widget(self.glade-get-widget($target-widget-name)));
      $filter-list .= new( :filter-type(SkipFilter), :$list-box);
    }

    else {
      die X::Library.new(:message("unknown listbox name"));
    }

    $filter-list.delete-filter-items;
  }

  #-----------------------------------------------------------------------------
  method exit-program ( ) {

    self.glade-main-quit();
  }

  #-----------------------------------------------------------------------------
  # widget can be one of GtkButton or GtkMenuItem
  method show-about-dialog ( :$widget, :$target-widget-name ) {

    my GTK::V3::Gtk::GtkAboutDialog $about-dialog .= new(
      :build-id('aboutDialog')
    );
    my GTK::V3::Gtk::GtkImage $logo .= new(
      :filename(%?RESOURCES<library-logo.png>.Str)
    );

    $about-dialog.set-logo($logo.get-pixbuf);
    $about-dialog.gtk-dialog-run;
    $about-dialog.gtk-widget-hide;
  }


  #-----------------------------------------------------------------------------
  # object is set to the id of the dialog to show
  method show-dialog ( :$target-widget-name ) {

    my GTK::V3::Gtk::GtkDialog $dialog .= new(
      :widget(self.glade-get-widget($target-widget-name))
    );
    $dialog.gtk-dialog-run;
  }

  #-----------------------------------------------------------------------------
  # object is set to the id of the dialog to close
  method hide-dialog ( :widget($button), :$target-widget-name ) {

    my GTK::V3::Gtk::GtkDialog $dialog .= new(
      :widget(self.glade-get-widget($target-widget-name))
    );
    $dialog.gtk-widget-hide;
  }
}
