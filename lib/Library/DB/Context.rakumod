use v6.d;

use Gnome::N::N-GObject;

#use Gnome::Gtk3::Dialog;

use Library::DB::Client;
use Library::DB::Filter;

use Library::Gui::OkMsgDialog;

#-------------------------------------------------------------------------------
unit class Library::DB::Context:auth<github:MARTIMM>:ver<0.0.1>;

#-------------------------------------------------------------------------------
has Library::DB::Client $!db;

#-------------------------------------------------------------------------------
#submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
# Database > Connect
method connect ( N-GObject $n-parameter ) {
  unless $!db {
    $!db .= new;
    $!db.connect;
  }
}

#-------------------------------------------------------------------------------
# Database > Disconnect
method disconnect ( N-GObject $n-parameter ) {
  $!db.cleanup;
  $!db = Nil;
}

#-------------------------------------------------------------------------------
# preprocess documents
method pre-process-docs ( N-GObject $n-parameter ) {
  note 'pre-process';

  if ?$!db {
  }

  else {
    self!show-msg(Q:to/EOMSG/);
      Cannot retrieve data from database,
      Please select <i>Connect</i> from the
      <i>Database</i> menu first.
      EOMSG
  }
}

#-------------------------------------------------------------------------------
# Database > Edit Tag
method edit-filters ( N-GObject $n-parameter ) {
#  note "Selected 'Edit Filters' from 'Database' menu";

  if ?$!db {
    my Library::DB::Filter $df .= new(:$!db);
    $df.show-dialog;
  }

  else {
    self!show-msg(Q:to/EOMSG/);
      Cannot retrieve data from database,
      Please select <i>Connect</i> from the
      <i>Database</i> menu first.
      EOMSG
  }
}

#-------------------------------------------------------------------------------
# show message
method !show-msg($message) {
  my Library::Gui::OkMsgDialog $msg-diag .= new(
    :message('DB Warning'), :secondary-message($message)
  );
  $msg-diag.run;
  $msg-diag.destroy;
}
