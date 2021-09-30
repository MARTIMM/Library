use v6;
use NativeCall;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;

use Gnome::Gdk3::Events;
use Gnome::Gdk3::Keysyms;
use Gnome::Gdk3::Types;

use Gnome::Gtk3::FileChooserDialog;
use Gnome::Gtk3::FileChooser;

use Library;
use Library::Storage;
use Library::MetaData::File;
use Library::MetaData::Directory;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

#-------------------------------------------------------------------------------
unit class Library::Gui::GatherData:auth<github:MARTIMM>;
also is Gnome::Gtk3::Glade::Engine;

#-------------------------------------------------------------------------------
has Bool $!recursive = False;

#-----------------------------------------------------------------------------
# widget can be one of GtkButton or GtkMenuItem
method show-file-chooser-dialog ( :$widget, :$target-widget-name --> Int ) {

  #$widget.debug(:on);

  my Gnome::Gtk3::FileChooserDialog $file-select-dialog .= new(
    :build-id($target-widget-name)
  );

  # get file chooser widget
  my Gnome::Gtk3::FileChooser $fc .= new(:widget($file-select-dialog));

  # set buttons in proper status
  my Int $o = $fc.get-show-hidden;
  my Gnome::Gtk3::CheckButton $b .= new(:build-id<showHideDialogCBttn>);
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

  1
}

#-----------------------------------------------------------------------------
# $target-widget-name is set to the id of the dialog to show
method show-hide-files ( :$widget, :$target-widget-name --> Int ) {

  my Gnome::Gtk3::FileChooserDialog $file-select-dialog .= new(
    :build-id($target-widget-name)
  );

  my Gnome::Gtk3::FileChooser $fc .= new(:widget($file-select-dialog));
  my Int $hidden = $fc.get-show-hidden;
  $fc.set-show-hidden(!?$hidden);

  1
}

#-----------------------------------------------------------------------------
# $target-widget-name is set to the id of the dialog to show
method multiple-select-files ( :$widget, :$target-widget-name --> Int ) {

  my Gnome::Gtk3::FileChooserDialog $file-select-dialog .= new(
    :build-id($target-widget-name)
  );

  my Gnome::Gtk3::FileChooser $fc .= new(:widget($file-select-dialog));
  my Int $multiple = $fc.get_select_multiple;
  $fc.set-select-multiple(!?$multiple);

  1
}

#-----------------------------------------------------------------------------
# File chooser dialog select button pressed
# $target-widget-name is set to the id of the dialog to show
method select-for-gather-process ( :$widget, :$target-widget-name --> Int ) {

  # This might take a while, so run in thread.
  my Promise $p = start {
#note "\nDialog id: $target-widget-name";
    my Gnome::Gtk3::FileChooserDialog $file-select-dialog .= new(
      :build-id($target-widget-name)
    );

    my Gnome::Gtk3::FileChooser $fc .= new(:widget($file-select-dialog));
    my Gnome::Glib::SList $fnames .= new(:gslist($fc.get-filenames));
#note "fn: ", $fnames;
    my Gnome::Gtk3::CheckButton $b .=
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

    1
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
