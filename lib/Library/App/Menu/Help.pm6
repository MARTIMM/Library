use v6.d;

#-------------------------------------------------------------------------------
unit class Library::App::Menu::Help:auth<github:MARTIMM>;

use Gnome::Gtk3::MenuItem;

use Library::App::Menu::Help::About;

#-------------------------------------------------------------------------------
#submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
# Help > About
method help-index (
  Int :$_handler_id, Gnome::Gtk3::MenuItem :_widget($menu-item)
) {
  note "Select 'index' from 'Help' menu";
}

#-------------------------------------------------------------------------------
# Help > About
method help-purpose (
  Int :$_handler_id, Gnome::Gtk3::MenuItem :_widget($menu-item)
) {
  note "Select 'purpose' from 'Help' menu";
}

#-------------------------------------------------------------------------------
# Help > About
method help-about (
  Int :$_handler_id, Gnome::Gtk3::MenuItem :_widget($menu-item)
) {
#  note "Select 'About' from 'Help' menu";
  my Library::App::Menu::Help::About $about .= new;
  $about.dialog-run;
  $about.widget-destroy;
}
