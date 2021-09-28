use v6;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;

use Library::Tools;
use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;

use Gnome::N::N-GObject;
use Gnome::Glib::List;
use Gnome::Gdk3::Events;
use Gnome::Gtk3::CheckButton;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::ListBoxRow;
use Gnome::Gtk3::ListBox;
use Gnome::Gtk3::Entry;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class Library::Gui::FilterList:auth<github:MARTIMM>;
also is Gnome::Gtk3::Glade::Engine;

#-----------------------------------------------------------------------------
enum FilterType is export < TagFilter SkipFilter >;

has $!filter-list;
has Int $!filter-type;
has Gnome::Gtk3::ListBox $!list-box;

#-----------------------------------------------------------------------------
#submethod BUILD ( ) { }

#-----------------------------------------------------------------------------
# Realize event of tagsDialog or skipDialog
# The realize event is fired when dialog is run. $target-widget-name
# has name of listbox.
method filter-dialog-realized (
  :widget($dialog), Str :$target-widget-name
  --> Int
) {
  self.refresh-filter-list( :widget($dialog), :$target-widget-name);

  1
}

#-----------------------------------------------------------------------------
# Click event of refreshTagListBttn refreshSkipListBttn
method refresh-filter-list (
  :widget($dialog), Str :$target-widget-name --> Int
) {

  my Gnome::Gtk3::ListBox $list-box;

  # test object for the listbox name to init the proper filter list
  if $target-widget-name eq 'tagFilterListBox' {
    $list-box .= new(:build-id($target-widget-name));
    self!set-filter( :filter-type(TagFilter), :$list-box);
  }

  elsif $target-widget-name eq 'skipDataListBox' {
    $list-box .= new(:build-id($target-widget-name));
    self!set-filter( :filter-type(SkipFilter), :$list-box);
  }

  else {
    die X::Library.new(:message("unknown listbox name"));
  }

  self!clean-filter-list;
  self!load-filter-list;

  1
}

#-----------------------------------------------------------------------------
method add-filter-item ( :widget($dialog), :$target-widget-name --> Int ) {

  my Gnome::Gtk3::Entry $input-entry;
  my Gnome::Gtk3::ListBox $list-box;

  # test object for the listbox name to init the proper filter list
  if $target-widget-name eq 'tagFilterListBox' {
    $list-box .= new(:build-id($target-widget-name));
    self!set-filter( :filter-type(TagFilter), :$list-box);
    $input-entry .= new(:build-id<inputTagFilterItemText>);
  }

  elsif $target-widget-name eq 'skipDataListBox' {
    $list-box .= new(:build-id($target-widget-name));
    self!set-filter( :filter-type(SkipFilter), :$list-box);
    $input-entry .= new(:build-id<inputSkipFilterItemText>);
  }

  else {
    die X::Library.new(:message("unknown listbox name"));
  }

  self!add-item($input-entry);

  1
}

#-----------------------------------------------------------------------------
method delete-filter-items ( :widget($button), :$target-widget-name --> Int ) {

Gnome::N::debug(:on);
  my Gnome::Gtk3::ListBox $list-box;

  # test object for the listbox name to init the proper filter list
  if $target-widget-name eq 'tagFilterListBox' {
    $list-box .= new(:build-id($target-widget-name));
    self!set-filter( :filter-type(TagFilter), :$list-box);
  }

  elsif $target-widget-name eq 'skipDataListBox' {
    $list-box .= new(:build-id($target-widget-name));
    self!set-filter( :filter-type(SkipFilter), :$list-box);
  }

  else {
    die X::Library.new(:message("unknown listbox name"));
  }

  self!delete-items;

  1
}

#--[ private stuff ]----------------------------------------------------------
method !set-filter (
  Int:D :$!filter-type, Gnome::Gtk3::ListBox:D :$!list-box
) {

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
method !clean-filter-list ( ) {

  loop {
    # Keep the index 0, entries will shift up after removal
    my N-GObject $nw = $!list-box.get-row-at-index(0) // N-GObject;
    last unless ?$nw;
    my Gnome::Gtk3::ListBoxRow $lb-row .= new(:widget($nw));
    $lb-row.gtk-widget-destroy;
  }
}

#-----------------------------------------------------------------------------
method !load-filter-list ( ) {

  my Array $list = $!filter-list.get-filter;

  for @$list -> $item-text {

    my Gnome::Gtk3::Label $label .= new(:text($item-text));
    $label.set-visible(True);

    my Gnome::Gtk3::CheckButton $check .= new(:label(''));
    $check.set-visible(True);

    my Gnome::Gtk3::Grid $grid .= new(:empty);
    $grid.set-visible(True);
    $grid.attach( $check(), 0, 0, 1, 1);
    $grid.attach( $label(), 1, 0, 1, 1);

    $!list-box.add($grid());
  }
}

#-----------------------------------------------------------------------------
# Add a text from a text entry to the filter list
method !add-item ( Gnome::Gtk3::Entry:D $entry ) {

  my Str $text = $entry.get-text;
  return unless ?$text;

  $!filter-list.set-filter( ($text,), :!drop);

  # Clear entry and refresh filter list
  $entry.set-text('');
  self!clean-filter-list;
  self!load-filter-list;
}

#-----------------------------------------------------------------------------
# Remove entries from the list when the checkbutton before it is checked
method !delete-items ( ) {

  my Array $delete-list = [];

  my $index = 0;
  loop {
note "select row $index";
    my $lb-row-widget = $!list-box.get-row-at-index($index);
    last unless $lb-row-widget.defined;
    $index++;

    my Gnome::Gtk3::ListBoxRow $lb-row .= new(:widget($lb-row-widget));
    my Gnome::Gtk3::Grid $grid .= new(:widget($lb-row.get_child()));
    my Gnome::Gtk3::CheckButton $check-box .= new(
      :widget($grid.get-child-at( 0, 0))
    );

    my Bool $checked = ? $check-box.get-active;
note "checked: $checked";
    if $checked {
      my Gnome::Gtk3::Label $label .= new(:widget($grid.get-child-at( 1, 0)));
note "label is $label.get-text()";
      $delete-list.push: $label.get-text;
    }
  }

note 'delete: ', $delete-list.join(', ');
  if ?$delete-list {
    $!filter-list.set-filter( @$delete-list, :drop);
    self!clean-filter-list;
    self!load-filter-list;
  }
}
