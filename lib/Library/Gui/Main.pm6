use v6;
#use lib "../gtk-glade/lib";
use GTK::Glade;

#-------------------------------------------------------------------------------
class Library::Gui::Main:auth<github:MARTIMM> is GTK::Glade::Engine {

  #-----------------------------------------------------------------------------
  method exit-program ( Hash $o, :$widget, :$data, :$object ) {

    gtk_main_quit();
  }

  #-----------------------------------------------------------------------------
  method show-about-dialog ( Hash $o, :$widget, :$data, :$object ) {

    my GtkWidget $dialog = $o<aboutDialog>;
    note "dialog object: ", $dialog;

    # Next calls are set on glade design
    # my GtkWidget $parent = $o<mainWindow>;
    # gtk_window_set_transient_for( $dialog, $parent);
    # gtk_window_set_modal( $dialog, True);

    given ( gtk_dialog_run($dialog) ) {
      default {
        .note;
      }
    }
  }

  #-----------------------------------------------------------------------------
  method close-about-dialog ( Hash $o, :$widget, :$data, :$object ) {

    my GtkWidget $dialog = $o<aboutDialog>;
note "dialog object: ", $dialog;
    gtk_dialog_response( $dialog, 1);
    gtk_widget_hide($dialog);
  }
}
