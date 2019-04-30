use v6;
use NativeCall;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;
use Library::Tools;
use Library::MetaData::File;
use Library::MetaData::Directory;

use GTK::Glade;
use GTK::Glade::Engine;

use GTK::V3::Gtk::GtkDialog;
use GTK::V3::Gtk::GtkAboutDialog;
use GTK::V3::Gtk::GtkImage;
use GTK::V3::Gtk::GtkGrid;
use GTK::V3::Gtk::GtkEntry;
use GTK::V3::Gtk::GtkFileChooserDialog;
use GTK::V3::Gtk::GtkFileChooser;
use GTK::V3::Gtk::GtkComboBoxText;

use GTK::V3::Glib::GSList;

use Config::TOML;
use MIME::Base64;
use MongoDB;

#note "\nGlib: ", GTK::V3::Glib::.keys;
#note "Gtk: ", GTK::V3::Gtk::.keys;

#note "Lib config in main: ", $Library::lib-cfg;

#-------------------------------------------------------------------------------
class Gui::Main is GTK::Glade::Engine {

  has Str $!id-list = 'library-id-0000000000';
  has Bool $!recursive = False;

  #-----------------------------------------------------------------------------
  #submethod BUILD ( ) { }

  #-----------------------------------------------------------------------------
  method exit-program ( ) {

    self.glade-main-quit();
  }

  #-----------------------------------------------------------------------------
  # widget can be one of GtkButton or GtkMenuItem
  method show-about-dialog ( :$widget ) {

    #$widget.debug(:on);

    my GTK::V3::Gtk::GtkAboutDialog $about-dialog .= new(
      :build-id('aboutDialog')
    );

    my GTK::V3::Gtk::GtkImage $logo .= new(
      :filename(%?RESOURCES<library-logo.png>.Str)
    );
    $about-dialog.set-logo($logo.get-pixbuf);

    $about-dialog.set-version($*version.Str);

    $about-dialog.gtk-dialog-run;
    $about-dialog.gtk-widget-hide;
  }

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
  # $target-widget-name is set to the id of the dialog to show
  method show-dialog ( :$widget, :$target-widget-name ) {

#    $widget.debug(:on);

    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));
    note "Dialog return value: ", $dialog.gtk-dialog-run;
#    $dialog.gtk-dialog-run;
  }

  #-----------------------------------------------------------------------------
  # $target-widget-name is set to the id of the dialog to close
  method hide-dialog ( :widget($button), :$target-widget-name ) {

    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));
    $dialog.gtk-widget-hide;
    #$dialog.gtk_dialog_response(GTK_RESPONSE_CLOSE);
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

  #-----------------------------------------------------------------------------
  # event from connectMBttn menu button
  method show-connect-dialog ( :$widget, Str :$target-widget-name ) {

#    $widget.debug(:on);
    my GTK::V3::Gtk::GtkComboBoxText $section-cbox .= new(
      :build-id<refineKeysCBox>
    );
    $section-cbox.remove-all;

    my Library::Configuration $config := $Library::lib-cfg;
#note "SK: ", $config.config<section-keys>;
    for @($config.config<section-keys>) -> $skey {
      $section-cbox.gtk-combo-box-text-prepend( $skey, $skey);
    }
    $section-cbox.gtk_combo_box_set_active(0);

    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));
    $dialog.gtk-dialog-run;
  }

  #-----------------------------------------------------------------------------
  # event from combobox selection on connect dialog
  method set-username ( :$widget, Str :$target-widget-name ) {

#    $widget.debug(:on);
    my GTK::V3::Gtk::GtkComboBoxText $section-cbox .= new(
      :build-id<refineKeysCBox>
    );
    my Str $section = $section-cbox.get-active-id;
    my Library::Configuration $config := $Library::lib-cfg;
    if ( $config.config<database>{$section}:exists and
         $config.config<database>{$section}<username>:exists
       ) {

      my $un = $config.config<database>{$section}<username>;
      my GTK::V3::Gtk::GtkEntry $un-entry .= new(:build-id<connectUNameEntry>);
      $un-entry.set-text($un);
    }
  }

  #-----------------------------------------------------------------------------
  # event from connectConnectDialogBttn on connect dialog
  method connect-server ( :$widget, Str :$target-widget-name ) {

#    $widget.debug(:on);

    my Library::Configuration $config := $Library::lib-cfg;
    my GTK::V3::Gtk::GtkDialog $dialog .= new(:build-id($target-widget-name));

    my GTK::V3::Gtk::GtkComboBoxText $section-cbox .= new(
      :build-id<refineKeysCBox>
    );
    my Str $section = $section-cbox.get-active-id;

    my GTK::V3::Gtk::GtkEntry $un-entry .= new(:build-id<connectUNameEntry>);
    my GTK::V3::Gtk::GtkEntry $pw-entry .= new(:build-id<connectPWordEntry>);

    my Str $un = $un-entry.get-text;
    my Str $pw = $pw-entry.get-text;
#note "n,p: $un, $pw";
    if ?$un and ?$pw {
      if $config.config<database>{$section}:exists {
        my $ecpw = MIME::Base64.encode-str(
          ($pw.encode Z+ 'abcdefghijklmnopqrstuvwxyz'.encode).join('.:.')
        );
#note "Epws: $ecpw, ", $config.config<database>{$section}<password>, ', ',
#     $ecpw eq $config.config<database>{$section}<password>;
        if $ecpw eq $config.config<database>{$section}<password> {
          $config.reconfig(:refine-key($section));
          my $topology = connect-meta-data-server();
          $dialog.gtk-widget-hide unless $topology ~~ any(TT-Unknown,TT-NotSet);
        }
      }
    }

    else {
      $config.reconfig(:refine-key($section));
      my $topology = connect-meta-data-server();
      $dialog.gtk-widget-hide unless $topology ~~ any(TT-Unknown,TT-NotSet);
    }
  }
}
