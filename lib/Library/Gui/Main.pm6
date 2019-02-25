use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library::Tools;
use Library::Gui::FilterList;
use Library::MetaData::File;
use Library::MetaData::Directory;

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
use GTK::V3::Glib::GFile;

note "\nGlib: ", GTK::V3::Glib::.keys;
#note "Gtk: ", GTK::V3::Gtk::.keys;

#-------------------------------------------------------------------------------
class Gui::Main is GTK::Glade::Engine {

  has Str $!id-list = 'library-id-0000000000';
  has Bool $!recursive = False;

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
      $list-box .= new(:build-id($target-widget-name));
      $filter-list .= new( :filter-type(TagFilter), :$list-box);
    }

    elsif $target-widget-name eq 'skipDataListBox' {
      $list-box .= new(:build-id($target-widget-name));
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
      $list-box .= new(:buil-id($target-widget-name));
      $filter-list .= new( :filter-type(TagFilter), :$list-box);
      $input-entry .= new(:build-id<inputTagFilterItemText>);
    }

    elsif $target-widget-name eq 'skipDataListBox' {
      $list-box .= new(:build-d($target-widget-name));
      $filter-list .= new( :filter-type(SkipFilter), :$list-box);
      $input-entry .= new(:build-id<inputSkipFilterItemText>);
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
      $list-box .= new(:build-d($target-widget-name));
      $filter-list .= new( :filter-type(TagFilter), :$list-box);
    }

    elsif $target-widget-name eq 'skipDataListBox' {
      $list-box .= new(:build-d($target-widget-name));
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
  method show-about-dialog ( :$widget ) {

    my GTK::V3::Gtk::GtkAboutDialog $about-dialog .= new(
      :build-id('aboutDialog')
    );

    my GTK::V3::Gtk::GtkImage $logo .= new(
      :filename(%?RESOURCES<library-logo.png>.Str)
    );
    $about-dialog.set-logo($logo.get-pixbuf);

    $about-dialog.set-version('0.12.0');

    $about-dialog.gtk-dialog-run;
    $about-dialog.gtk-widget-hide;
  }

  #-----------------------------------------------------------------------------
  # widget can be one of GtkButton or GtkMenuItem
  method show-file-chooser-dialog ( :$widget, :$target-widget-name ) {

note "Dialog id: $target-widget-name, ", $widget;
    $widget.debug(:on);

    my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    # get file chooser widget
    my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));

    # set buttons in proper status
    my Int $o = $fc.get-show-hidden;
    my GTK::V3::Gtk::GtkCheckButton $b .= new(:build-id<showHideDialogCBttn>);
note "Hide: ", $o;
    $b.set-active($o);
    $fc.set-show-hidden($o);  # is not set properly when started firt time
note "Set hide: ", $b.get-active;

    $o = $fc.get-select-multiple;
    $b .= new(:build-id<multSelDialogCBttn>);
    $b.set-active($o);
    $fc.set-select-multiple($o);

    $b .= new(:build-id<recursiveDialogCBttn>);
    $b.set-active(0);

    $file-select-dialog.gtk-dialog-run;
    $file-select-dialog.gtk-widget-hide;
  }

  #-----------------------------------------------------------------------------
  # $target-widget-name is set to the id of the dialog to show
  method show-hide-files ( :$widget, :$target-widget-name ) {

note "Dialog id: $target-widget-name";
    my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));
    my Int $hidden = $fc.get-show-hidden;
note "Files hidden?: ", $hidden;
    $fc.set-show-hidden(!?$hidden);
  }

  #-----------------------------------------------------------------------------
  # $target-widget-name is set to the id of the dialog to show
  method multiple-select-files ( :$widget, :$target-widget-name ) {

note "Dialog id: $target-widget-name";
    my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));
    my Int $multiple = $fc.get_select_multiple;
note "Multiple file select?: ", $multiple;
    $fc.set-select-multiple(!?$multiple);
  }

  #-----------------------------------------------------------------------------
  # File chooser dialog select button pressed
  # $target-widget-name is set to the id of the dialog to show
  method select-for-gather-process ( :$widget, :$target-widget-name ) {

    # This might take a while, so run in thread.
    my Promise $p = start {
  note "\nDialog id: $target-widget-name";
      my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
        :build-id($target-widget-name)
      );

      my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));
      my GTK::V3::Glib::GSList $fnames .= new(:gslist($fc.get-filenames));
      note "fn: ", $fnames;
      my GTK::V3::Gtk::GtkCheckButton $b .=
        new(:build-id<recursiveDialogCBttn>
      );
      $!recursive = ?$b.get-active;

      my @files-to-process = ();
      for ^$fnames.g-slist-length -> $i {
        @files-to-process.push($fnames.nth-data-str($i));
note "get $fnames.nth-data-str($i)";
      }

      # get the file and directory names and create Library::MetaData objects
      # any filtered objects are not returned and not saved in database
      my Seq $fp := gather for @files-to-process -> $object {
      #my Array $fp = [gather for @files-to-process -> $object {
        note "Process $object";
        self!process-directory($object);
      };
      #}];
#note "gathered ", $fp;

      # then add tags to the documents
      for @$fp -> $meta-object {
      #loop ( my Int $i = 0; $i < $fp.elems; $i++ ) {
      #  my $meta-object = $fp[$i];
      #  note "Tag[$i], ", $meta-object;
        note "Tag, ", $meta-object;
        $meta-object.set-metameta-tags;
      }

      $fnames.g-slist-free();
    }
  }

  #-----------------------------------------------------------------------------
  # $target-widget-name is set to the id of the dialog to show
  method show-dialog ( :$target-widget-name ) {

    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));
    $dialog.gtk-dialog-run;
  }

  #-----------------------------------------------------------------------------
  # $target-widget-name is set to the id of the dialog to close
  method hide-dialog ( :widget($button), :$target-widget-name ) {

    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));
    $dialog.gtk-widget-hide;
  }

  #-----------------------------------------------------------------------------
  # recursively gather objects from this object if directory.
  # must run within a gather block.
  # take returns Library::MetaData objects when the object is not ignored
  method !process-directory ( Str $o ) {
    my Library::MetaData::Directory $mdir;
    my Library::MetaData::File $mfile;

    # test if $o is a directory
    if $o.IO.d {
      # first queue this directory object
      $mdir .= new(:object($o));
note "Take ", $mdir;
      take $mdir unless $mdir.ignore-object;

      # if a directory object is filtered out, al descendends are too
      return if $mdir.ignore-object;

      # then check if the contents of dir must be sought
      if $!recursive {
        for dir($o) -> $object {
          if $object.d {
            # queue this directory and process
            $mdir .= new(:$object);
note "Take ", $mdir;
            take $mdir unless $mdir.ignore-object;
            self!process-directory($object.Str) unless $mdir.ignore-object;
          }

          else {
            # queue this file
            $mfile .= new(:$object);
note "Take ", $mfile;
            take $mfile unless $mfile.ignore-object;
          }
        }
      }
    }

    elsif $o.IO.f {
      # queue this file
      $mfile .= new(:object($o));
note "Take ", $mfile;
      take $mfile unless $mfile.ignore-object;
    }

    else {
      note "Special file $o ignored";
    }
  }
}
