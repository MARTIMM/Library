use v6;
use NativeCall;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;
use Library::Tools;

use GTK::Glade;
use GTK::Glade::Engine;

use GTK::V3::Gtk::GtkDialog;
use GTK::V3::Gtk::GtkAboutDialog;
use GTK::V3::Gtk::GtkImage;
use GTK::V3::Gtk::GtkEntry;
use GTK::V3::Gtk::GtkComboBoxText;

use GTK::V3::Glib::GSList;

use MIME::Base64;
use MongoDB;

#note "\nGlib: ", GTK::V3::Glib::.keys;
#note "Gtk: ", GTK::V3::Gtk::.keys;

#note "Lib config in main: ", $Library::lib-cfg;

#-------------------------------------------------------------------------------
class Gui::Main is GTK::Glade::Engine {

  has Str $!id-list = 'library-id-0000000000';

  #-----------------------------------------------------------------------------
  #submethod BUILD ( ) { }

  #-----------------------------------------------------------------------------
  method exit-program ( ) {
#TODO check if data is saved
note "Save data ...";

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

    my Bool $connected = False;

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
     $ecpw eq $config.config<database>{$section}<password>;
        if $ecpw eq $config.config<database>{$section}<password> {
          $config.reconfig(:refine-key($section));
          $connected = self!connect;
        }
      }
    }

    else {
      $config.reconfig(:refine-key($section));
      $connected = self!connect;
    }

    $dialog.gtk-widget-hide if $connected;
  }

  #-----------------------------------------------------------------------------
  # connect to server
  method !connect ( --> Bool ) {

    my Bool $connected = True;
    my Instant $t0 = now;
    my GTK::V3::Gtk::GtkLabel $status-label .= new(:build-id<statusLabel>);

    connect-meta-data-server();
    while db-topology() ~~ any( TT-Unknown, TT-NotSet) {

      if now - $t0 > 5.0 {
        $status-label.set-text('Failed to connect');
        $connected = False;
      }

      else {
        $status-label.set-text('Connecting ...');
      }

      sleep 0.6;
    }

    if $connected {
      $status-label.set-text(
        [~] 'Connected to server ', db-server, ', topology: ', db-topology()
      );
    }

    $connected
  }
}
