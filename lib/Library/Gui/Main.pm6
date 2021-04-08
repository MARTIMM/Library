use v6;
use NativeCall;

use Library;
use Library::Configuration;
use Library::Tools;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::AboutDialog;
use Gnome::Gtk3::Image;
use Gnome::Gtk3::Entry;
use Gnome::Gtk3::ComboBoxText;

use Gnome::Glib::SList;

use MIME::Base64;
use MongoDB;

#-------------------------------------------------------------------------------
unit class Library::Gui::Main:auth<github:MARTIMM>;
also is Gnome::Gtk3::Glade::Engine;

#-------------------------------------------------------------------------------
has Str $!id-list = 'library-id-0000000000';

#-------------------------------------------------------------------------------
#submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
method exit-program ( --> Int ) {
#TODO check if data is saved
note "Save data ...";

  self.glade-main-quit();

  1
}

#-------------------------------------------------------------------------------
# widget can be one of GtkButton or GtkMenuItem
method show-about-dialog ( :$widget --> Int ) {

  #$widget.debug(:on);

  my Gnome::Gtk3::AboutDialog $about-dialog .= new(
    :build-id('aboutDialog')
  );

  my Gnome::Gtk3::Image $logo .= new(
    :filename(%?RESOURCES<library-logo.png>.Str)
  );
  $about-dialog.set-logo($logo.get-pixbuf);

  $about-dialog.set-version($*version.Str);

  note "About dialog return value: ", $about-dialog.gtk-dialog-run;
  $about-dialog.gtk-widget-hide;

  1
}

#-------------------------------------------------------------------------------
# $target-widget-name is set to the id of the dialog to show
method show-dialog ( :$widget, :$target-widget-name --> Int ) {

note "show-dialog: $target-widget-name";

  my Gnome::Gtk3::Dialog $dialog .= new(:build-id($target-widget-name));
  note "Dialog return value: ", $dialog.gtk-dialog-run;
#    $dialog.gtk-dialog-run;

  1
}

#-------------------------------------------------------------------------------
# $target-widget-name is set to the id of the dialog to close
method hide-dialog ( :widget($button), :$target-widget-name --> Int ) {

  my Gnome::Gtk3::Dialog $dialog .= new(:build-id($target-widget-name));
  $dialog.gtk-widget-hide;
  #$dialog.gtk_dialog_response(GTK_RESPONSE_CLOSE);

  1
}

#-------------------------------------------------------------------------------
# event from connectMBttn menu button
method show-connect-dialog ( :$widget, Str :$target-widget-name --> Int ) {

#    $widget.debug(:on);
  my Gnome::Gtk3::ComboBoxText $section-cbox .= new(
    :build-id<refineKeysCBox>
  );
  $section-cbox.remove-all;

  my Library::Configuration $config := $Library::lib-cfg;
#note "SK: ", $config.config<section-keys>;
  for @($config.config<section-keys>) -> $skey {
    $section-cbox.gtk-combo-box-text-prepend( $skey, $skey);
  }
  $section-cbox.gtk_combo_box_set_active(0);

  my Gnome::Gtk3::Dialog $dialog .= new(:build-id($target-widget-name));
  $dialog.gtk-dialog-run;

  1
}

#-------------------------------------------------------------------------------
# event from combobox selection on connect dialog
method set-username ( :$widget, Str :$target-widget-name --> Int ) {

#    $widget.debug(:on);
  my Gnome::Gtk3::ComboBoxText $section-cbox .= new(
    :build-id<refineKeysCBox>
  );
  my Str $section = $section-cbox.get-active-id;
  my Library::Configuration $config := $Library::lib-cfg;
  if ( $config.config<database>{$section}:exists and
       $config.config<database>{$section}<username>:exists
     ) {

    my $un = $config.config<database>{$section}<username>;
    my Gnome::Gtk3::Entry $un-entry .= new(:build-id<connectUNameEntry>);
    $un-entry.set-text($un);
  }

  1
}

#-------------------------------------------------------------------------------
# event from connectConnectDialogBttn on connect dialog
method connect-server ( :$widget, Str :$target-widget-name --> Int ) {

#    $widget.debug(:on);

  my Bool $connected = False;

  my Library::Configuration $config := $Library::lib-cfg;
  my Gnome::Gtk3::Dialog $dialog .= new(:build-id($target-widget-name));

  my Gnome::Gtk3::ComboBoxText $section-cbox .= new(
    :build-id<refineKeysCBox>
  );
  my Str $section = $section-cbox.get-active-id;

  my Gnome::Gtk3::Entry $un-entry .= new(:build-id<connectUNameEntry>);
  my Gnome::Gtk3::Entry $pw-entry .= new(:build-id<connectPWordEntry>);

  my Str $un = $un-entry.get-text;
  my Str $pw = $pw-entry.get-text;
#note "n,p: $un, $pw";
  if ?$un and ?$pw {
    if $config.config<database>{$section}:exists {
      my $ecpw = MIME::Base64.encode-str(
        ($pw.encode Z+ 'abcdefghijklmnopqrstuvwxyz'.encode).join('.:.')
      );
#note "Epws: $ecpw, ", $config.config<database>{$section}<password>, ', ', $ecpw eq $config.config<database>{$section}<password>;
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

  1
}

#-------------------------------------------------------------------------------
# connect to server
method !connect ( --> Bool ) {

  my Bool $connected = True;
  my Instant $t0 = now;
  my Gnome::Gtk3::Label $status-label .= new(:build-id<statusLabel>);

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
