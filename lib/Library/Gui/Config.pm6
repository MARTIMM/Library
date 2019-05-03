use v6;
use NativeCall;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use GTK::Glade;
use GTK::Glade::Engine;

use GTK::V3::Gdk::GdkEventTypes;
use GTK::V3::Gdk::GdkKeysyms;
use GTK::V3::Gdk::GdkTypes;

use GTK::V3::Gtk::GtkGrid;
use GTK::V3::Gtk::GtkListBox;

use Library;
use Library::Storage;
use Library::Configuration;
use Library::Tools;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

use Config::TOML;

#`{{
use Library::Configuration;
use Library::Tools;
use Library::MetaData::File;
use Library::MetaData::Directory;

use GTK::V3::Gtk::GtkDialog;
use GTK::V3::Gtk::GtkImage;
use GTK::V3::Gtk::GtkGrid;
use GTK::V3::Gtk::GtkEntry;
use GTK::V3::Gtk::GtkFileChooser;
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
class Gui::Config is GTK::Glade::Engine {


  #-----------------------------------------------------------------------------
  method show-config-dialog ( :$widget, Str :$target-widget-name ) {

#    $widget.debug(:on);

#!! load from toml!!
    my Library::Configuration $config := $Library::lib-cfg;
#    $config.save-config;
    my Hash $cfg := $config.config;
#note "Cfg: ", $cfg.keys;


    # Clear grid by removing the first column 3 times.
    my GTK::V3::Gtk::GtkGrid $grid .= new(:build-id<configDialogGrid>);
    $grid.remove-column(0) for ^3;

    #my Array[Pair] $pairs = [];


    my Str $key = 'server';
    my Str $value = $cfg<connection><server>;
    my GTK::V3::Gtk::GtkLabel $cfg-label .= new(:label($key));
    $cfg-label.set-visible(True);
    my GTK::V3::Gtk::GtkEntry $cfg-entry .= new(:empty);
    $cfg-entry.set-visible(True);
    $cfg-entry.set-text($value);
    $grid.gtk-grid-attach( $cfg-label, 0, 0, 1, 1);
    $grid.gtk-grid-attach( $cfg-entry, 1, 0, 1, 1);


    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));
    $dialog.gtk-dialog-run;
  }
}
