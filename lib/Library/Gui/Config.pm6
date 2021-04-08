use v6;
use NativeCall;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;

use Gnome::Gdk3::Events;
use Gnome::Gdk3::Keysyms;
use Gnome::Gdk3::Types;

use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ListBox;

use Library;
use Library::Storage;
use Library::Configuration;
use Library::Tools;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

use Config::TOML;

#-------------------------------------------------------------------------------
unit class Library::Gui::Config:auth<github:MARTIMM>;
also is Gnome::Gtk3::Glade::Engine;

#-----------------------------------------------------------------------------
method show-config-dialog ( :$widget, Str :$target-widget-name --> Int ) {


#!! load from toml!!
  my Library::Configuration $config := $Library::lib-cfg;
#    $config.save-config;
  my Hash $cfg := $config.config;
#note "Cfg: ", $cfg.keys;


  # Clear grid by removing the first column 3 times.
  my Gnome::Gtk3::Grid $grid .= new(:build-id<configDialogGrid>);
  $grid.remove-column(0) for ^3;

  #my Array[Pair] $pairs = [];


  my Str $key = 'server';
  my Str $value = $cfg<connection><server>;
  my Gnome::Gtk3::Label $cfg-label .= new(:label($key));
  $cfg-label.set-visible(True);
  my Gnome::Gtk3::Entry $cfg-entry .= new(:empty);
  $cfg-entry.set-visible(True);
  $cfg-entry.set-text($value);
  $grid.gtk-grid-attach( $cfg-label, 0, 0, 1, 1);
  $grid.gtk-grid-attach( $cfg-entry, 1, 0, 1, 1);


  my Gnome::Gtk3::Dialog $dialog .= new(:build-id($target-widget-name));
  $dialog.gtk-dialog-run;

  1
}
