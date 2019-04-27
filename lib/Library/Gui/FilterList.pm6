use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use GTK::Glade;
use GTK::Glade::Engine;

use Library::Tools;
use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;

use GTK::V3::Glib::GList;

use GTK::V3::Gtk::GtkBin;
use GTK::V3::Gtk::GtkCheckButton;
use GTK::V3::Gtk::GtkGrid;
use GTK::V3::Gtk::GtkLabel;
use GTK::V3::Gtk::GtkListBox;
use GTK::V3::Gtk::GtkEntry;

#-------------------------------------------------------------------------------
class Gui::FilterList {
  also is GTK::Glade::Engine;

  #-----------------------------------------------------------------------------
  enum FilterType is export < TagFilter SkipFilter >;

  has $!filter-list;
  has Int $!filter-type;
  has GTK::V3::Gtk::GtkListBox $!list-box;

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

    #$dialog.debug(:on);

    my GTK::V3::Gtk::GtkListBox $list-box;

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
  }

  #-----------------------------------------------------------------------------
  method add-filter-item ( :widget($dialog), :$target-widget-name ) {

    #$dialog.debug(:on);

    my GTK::V3::Gtk::GtkEntry $input-entry;
    my GTK::V3::Gtk::GtkListBox $list-box;

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
  }

  #-----------------------------------------------------------------------------
  method delete-filter-items ( :widget($button), :$target-widget-name ) {

    #$button.debug(:on);

    my GTK::V3::Gtk::GtkListBox $list-box;

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
  }

  #--[ private stuff ]----------------------------------------------------------
  method !set-filter (
    Int:D :$!filter-type, GTK::V3::Gtk::GtkListBox:D :$!list-box
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

    my Array $list = $!filter-list.get-filter;

    loop {
      # Keep the index 0, entries will shift up after removal
      my $nw = $!list-box.get-row-at-index(0);
      last unless ?$nw;
      my GTK::V3::Gtk::GtkBin $lb-row .= new(:widget($nw));
      $lb-row.gtk-widget-destroy;
    }
  }

  #-----------------------------------------------------------------------------
  method !load-filter-list ( ) {

    my Array $list = $!filter-list.get-filter;

    for @$list -> $item-text {

      my GTK::V3::Gtk::GtkLabel $label .= new(:label($item-text));
      $label.set-visible(True);

      my GTK::V3::Gtk::GtkCheckButton $check .= new(:label(''));
      $check.set-visible(True);

      my GTK::V3::Gtk::GtkGrid $grid .= new(:empty);
      $grid.set-visible(True);
      $grid.gtk-grid-attach( $check(), 0, 0, 1, 1);
      $grid.gtk-grid-attach( $label(), 1, 0, 1, 1);

      $!list-box.gtk-container-add($grid());
    }
  }

  #-----------------------------------------------------------------------------
  # Add a text from a text entry to the filter list
  method !add-item ( GTK::V3::Gtk::GtkEntry:D $entry ) {

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
      my $lb-row-widget = $!list-box.get-row-at-index($index);
      last unless ?$lb-row-widget;
      $index++;

      my GTK::V3::Gtk::GtkBin $lb-row .= new(:widget($lb-row-widget));
      my GTK::V3::Gtk::GtkGrid $grid .= new(:widget($lb-row.get_child()));
      my GTK::V3::Gtk::GtkCheckButton $check-box .= new(
        :widget($grid.get-child-at( 0, 0))
      );

      my Bool $checked = ? $check-box.get-active;
      if $checked {
        my GTK::V3::Gtk::GtkLabel $label .= new(
          :widget($grid.get-child-at( 1, 0))
        );

        $delete-list.push: $label.get-text;
      }
    }

    if ?$delete-list {
      $!filter-list.set-filter( @$delete-list, :drop);
      self!clean-filter-list;
      self!load-filter-list;
    }
  }
}
