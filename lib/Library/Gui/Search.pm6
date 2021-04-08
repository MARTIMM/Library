use v6;
use NativeCall;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;

use Gnome::Gdk3::Events;
use Gnome::Gdk3::Keysyms;
use Gnome::Gdk3::Types;

use Gnome::Gtk3::SearchEntry;
use Gnome::Gtk3::ListBox;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::RadioButton;

use Gnome::N::N-GObject;
use Gnome::Glib::SList;

use Library;
use Library::Storage;

use MongoDB;
use MongoDB::Cursor;
use BSON::Document;

#-------------------------------------------------------------------------------
unit class Library::Gui::Search:auth<github:MARTIMM>;
also is Gnome::Gtk3::Glade::Engine;

#-------------------------------------------------------------------------------
has Library::Storage $!dbcfg;
has Gnome::Gtk3::ListBox $!search-result-lbx;
has Hash $!search-docs;

#-----------------------------------------------------------------------------
submethod BUILD ( ) {

  # must activate the normal as default
  my Gnome::Gtk3::RadioButton $ns .= new(:build-id<normalSearch>);
  $ns.set-active(1);
}

#-----------------------------------------------------------------------------
method search-on-enter (
  GdkEvent $event,  Gnome::Gtk3::SearchEntry :widget($search-entry),
  Str :target-widget-name($search-result-lbx-name)
  --> Int
) {

  # test for keyboard input using GdkEventAny structure
  return unless GdkEventType($event.event-any.type) ~~ GDK_KEY_PRESS;

  my GdkEventKey $event-key := $event.event-key;

#note "key: ", $event-key.keyval.fmt('0x%04x');
#note "hw key: ", $event-key.hardware_keycode;
#note "Return pressed" if $event-key.keyval == GDK_KEY_Return;

  # test for return key without any modifier key
  return unless $event-key.keyval == GDK_KEY_Return
                and $event-key.state == 0;

  # get the search text and prepare search
  my Str $search-text = $search-entry.get-text;
note "Search for '$search-text'";
  return unless ?$search-text;

  # get the listbox where all must be stored
  $!search-result-lbx .= new(:build-id($search-result-lbx-name));

  # if there is a result, clean the result listbox
  self!clean-search-list;
  $!search-docs = {};

  # search in database
  $!dbcfg .= new(:collection-key<meta-data>);
  my MongoDB::Cursor $c = $!dbcfg.find: (:name($search-text), );
note "Cursor: ", $c//'-';
  return unless ?$c;

  my BSON::Document $doc;
  while ( $doc = $c.fetch ) {
note "Name found: ", $doc.perl;

    # The oid id must be saved to look it up later but must not be visible
    my Str $oid = $doc<_id>.oid>>.fmt('%02x').join('');
    my Gnome::Gtk3::Label $id .= new(:label($oid));
    $id.set-visible(False);
    my Gnome::Gtk3::Label $name .= new(:label($doc<name>));
    $name.set-visible(True);

    my Gnome::Gtk3::Grid $grid .= new(:empty);
    $grid.set-visible(True);
    $grid.gtk-grid-attach( $id(), 0, 0, 1, 1);
    $grid.gtk-grid-attach( $name(), 1, 0, 1, 1);

    $!search-result-lbx.gtk-container-add($grid());
    $!search-docs{$id} = $doc;
  }

  1
}

#-----------------------------------------------------------------------------
method get-user-meta ( N-GObject $native-lb-row --> Int ) {

  self!clean-select-list;

  my Gnome::Gtk3::Bin $lb-row .= new(:widget($native-lb-row));
note "select row: ", $lb-row.get_child();
  my Gnome::Gtk3::Grid $grid .= new(:widget($lb-row.get_child()));
  my Gnome::Gtk3::Label $id .= new(:widget($grid.get-child-at( 0, 0)));
note "Id: ", $id.get-text;

  my BSON::Document $doc = $!search-docs{$id.get-text};

  1
}

#`{{

#-----------------------------------------------------------------------------
method  ( ) {

}
}}

#-----------------------------------------------------------------------------
method !clean-search-list ( ) {

  loop {
    # Keep the index 0, entries will shift up after removal
    my $nw = $!search-result-lbx.get-row-at-index(0);
    last unless ?$nw;
    my Gnome::Gtk3::Bin $lb-row .= new(:widget($nw));
    $lb-row.gtk-widget-destroy;
  }
}

#-----------------------------------------------------------------------------
method !clean-select-list ( ) {

  loop {
    # Keep the index 0, entries will shift up after removal
    my $nw = $!search-result-lbx.get-row-at-index(0);
    last unless ?$nw;
    my Gnome::Gtk3::Bin $lb-row .= new(:widget($nw));
    $lb-row.gtk-widget-destroy;
  }
}
