use v6.d;

#-------------------------------------------------------------------------------
use Gnome::Glib::Error;

use Gnome::Gdk3::Pixbuf;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::MessageDialog;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::StyleContext;

#-------------------------------------------------------------------------------
unit class Library::Gui::OkMsgDialog;
also is Gnome::Gtk3::MessageDialog;

#-------------------------------------------------------------------------------
submethod new ( Str :$message, |c ) {

  # let the Gnome::Gtk3::MessageDialog class process the options
  self.bless(
    :GtkMessageDialog, :flags(GTK_DIALOG_MODAL), :type(GTK_MESSAGE_WARNING),
    :buttons(GTK_BUTTONS_OK), :markup-message($message),
    |c
    );
}

#-------------------------------------------------------------------------------
submethod BUILD ( *%options ) {
  self.set-position(GTK_WIN_POS_MOUSE);
  self.set-keep-above(True);
  self.set-default-response(GTK_RESPONSE_NO);

  my Gnome::Gdk3::Pixbuf $win-icon .= new(
    :file("Old/I/p{5.rand.Int}.jpg")
#    :file(%?RESOURCES<library-logo.png>.Str)
  );
  my Gnome::Glib::Error $e = $win-icon.last-error;
  if $e.is-valid {
    note "Error icon file: $e.message()";
  }

  else {
    self.set-icon($win-icon);
  }

  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAMsgDialog');
}

#-------------------------------------------------------------------------------
