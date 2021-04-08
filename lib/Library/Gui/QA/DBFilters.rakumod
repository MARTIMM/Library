use v6.d;


use Gnome::Gtk3::Dialog;
#use Gnome::Gtk3::Main;
#use Gnome::Gtk3::Enums;
#use Gnome::Gtk3::Window;
#use Gnome::Gtk3::Grid;
#use Gnome::Gtk3::Button;
#use Gnome::Gtk3::Label;

use QA::Gui::SheetSimple;
#use QA::Gui::Frame;
#use QA::Gui::Value;
#use QA::Types;
#use QA::Question;

use Gnome::N::X;

#-------------------------------------------------------------------------------
unit class Library::Gui::QA::DBFilters:auth<github:MARTIMM>:ver<0.1.0>;

has Str $!sheet-name is required;

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$!sheet-name ) { }

#-------------------------------------------------------------------------------
method show-dialog ( --> Hash ) {
  my QA::Gui::SheetSimple $sheet-dialog .= new(
    :$!sheet-name, :show-cancel-warning, :!save-data
  );

  my Int $response = $sheet-dialog.show-sheet;
  self.display-result( $response, $sheet-dialog);
  $sheet-dialog.result-user-data // %()
}

#-------------------------------------------------------------------------------
method display-result ( Int $response, QA::Gui::Dialog $dialog ) {

  note "Dialog return status: ", GtkResponseType($response);
  self.show-hash($dialog.result-user-data) if $response ~~ GTK_RESPONSE_OK;
  $dialog.widget-destroy unless $response ~~ GTK_RESPONSE_NONE;
}

#-------------------------------------------------------------------------------
method show-hash ( Hash $h, Int :$i is copy ) {
  if $i.defined {
    $i++;
  }

  else {
    note '';
    $i = 0;
  }

  for $h.keys.sort -> $k {
    if $h{$k} ~~ Hash {
      note '  ' x $i, "$k => \{";
      self.show-hash( $h{$k}, :$i);
      note '  ' x $i, '}';
    }

    elsif $h{$k} ~~ Array {
      note '  ' x $i, "$k => $h{$k}.perl()";
    }

    else {
      note '  ' x $i, "$k => $h{$k}";
    }
  }

  $i--;
}
