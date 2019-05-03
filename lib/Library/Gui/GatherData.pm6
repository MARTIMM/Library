use v6;
use NativeCall;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use GTK::Glade;
use GTK::Glade::Engine;

use GTK::V3::Gdk::GdkEventTypes;
use GTK::V3::Gdk::GdkKeysyms;
use GTK::V3::Gdk::GdkTypes;

use GTK::V3::Gtk::GtkFileChooserDialog;
use GTK::V3::Gtk::GtkFileChooser;

use Library;
use Library::Storage;
use Library::MetaData::File;
use Library::MetaData::Directory;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

#`{{
use Library::Configuration;
use Library::Tools;
use Library::MetaData::File;
use Library::MetaData::Directory;

use GTK::V3::Gtk::GtkDialog;
use GTK::V3::Gtk::GtkImage;
use GTK::V3::Gtk::GtkGrid;
use GTK::V3::Gtk::GtkEntry;
use GTK::V3::Gtk::GtkComboBoxText;

use GTK::V3::Glib::GSList;

use Config::TOML;
use MIME::Base64;
use MongoDB;

#note "\nGlib: ", GTK::V3::Glib::.keys;
#note "Gtk: ", GTK::V3::Gtk::.keys;

#note "Lib config in main: ", $Library::lib-cfg;
}}

#-------------------------------------------------------------------------------
class Gui::GatherData is GTK::Glade::Engine {

  has Bool $!recursive = False;

  #-----------------------------------------------------------------------------
  # widget can be one of GtkButton or GtkMenuItem
  method show-file-chooser-dialog ( :$widget, :$target-widget-name ) {

    #$widget.debug(:on);

    my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    # get file chooser widget
    my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));

    # set buttons in proper status
    my Int $o = $fc.get-show-hidden;
    my GTK::V3::Gtk::GtkCheckButton $b .= new(:build-id<showHideDialogCBttn>);
    $b.set-active($o);
    $fc.set-show-hidden($o);  # is not set properly when started first time

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

    my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));
    my Int $hidden = $fc.get-show-hidden;
    $fc.set-show-hidden(!?$hidden);
  }

  #-----------------------------------------------------------------------------
  # $target-widget-name is set to the id of the dialog to show
  method multiple-select-files ( :$widget, :$target-widget-name ) {

    my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));
    my Int $multiple = $fc.get_select_multiple;
    $fc.set-select-multiple(!?$multiple);
  }

  #-----------------------------------------------------------------------------
  # File chooser dialog select button pressed
  # $target-widget-name is set to the id of the dialog to show
  method select-for-gather-process ( :$widget, :$target-widget-name ) {

    # This might take a while, so run in thread.
    my Promise $p = start {
#note "\nDialog id: $target-widget-name";
      my GTK::V3::Gtk::GtkFileChooserDialog $file-select-dialog .= new(
        :build-id($target-widget-name)
      );

      my GTK::V3::Gtk::GtkFileChooser $fc .= new(:widget($file-select-dialog));
      my GTK::V3::Glib::GSList $fnames .= new(:gslist($fc.get-filenames));
#note "fn: ", $fnames;
      my GTK::V3::Gtk::GtkCheckButton $b .=
        new(:build-id<recursiveDialogCBttn>
      );
      $!recursive = ?$b.get-active;

      my @files-to-process = ();
      for ^$fnames.g-slist-length -> $i {
        @files-to-process.push($fnames.nth-data-str($i));
#note "get $fnames.nth-data-str($i)";
      }

      # get the file and directory names and create Library::MetaData objects
      # any filtered objects are not returned and not saved in database
      my Seq $fp := gather for @files-to-process -> $object {
        note "Process $object";
        self!process-directory($object);
      };
#note "gathered ", $fp if $*debug;

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
  # recursively gather objects from this object if directory.
  # must run within a gather block.
  # take returns Library::MetaData objects when the object is not ignored
  method !process-directory ( Str $o ) {
    my Library::MetaData::Directory $mdir;
    my Library::MetaData::File $mfile;

#note "O: $o.IO.f(), $o.IO.d()";
    # test if $o is a directory
    if $o.IO.d {
      # first queue this directory object
      $mdir .= new(:object($o));
#note "Take ", $mdir;
      take $mdir unless $mdir.ignore-object;

      # if a directory object is filtered out, al descendends are too
      return if $mdir.ignore-object;

      # then check if the contents of dir must be sought
      if $!recursive {
        for dir($o) -> $object {
          if $object.d {
            # queue this directory and process
            $mdir .= new(:$object);
#note "Take ", $mdir;
            take $mdir unless $mdir.ignore-object;
            self!process-directory($object.Str) unless $mdir.ignore-object;
          }

          else {
            # queue this file
            $mfile .= new(:$object);
#note "Take ", $mfile;
            take $mfile unless $mfile.ignore-object;
          }
        }
      }
    }

    elsif $o.IO.f {
      # queue this file
      $mfile .= new(:object($o));
#note "Take ", $mfile;
      take $mfile unless $mfile.ignore-object;
    }

    else {
      note "Special file $o ignored";
    }
  }
}
