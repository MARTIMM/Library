use v6.d;

use Getopt::Long;

use Gnome::N::N-GObject;

use Gnome::Gio::Enums;
use Gnome::Gio::Resource;
use Gnome::Gio::ApplicationCommandLine;

use Gnome::Gtk3::Application;

use Library::App::MainWindow;
use Library::App::TypeDataStore;

#use QA::Types;

#-------------------------------------------------------------------------------
unit class Library::App::Application:auth<github:MARTIMM>:ver<0.2.0>;
also is Gnome::Gtk3::Application;

constant library-id = 'io.github.martimm.library';

#`{{
#-------------------------------------------------------------------------------
# let QA look at the proper locations
given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfg-root(library-id);
#    .list-dirs.note;
}
}}

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk3::Application class process the options
  self.bless(
    :GtkApplication, :app-id(Library::App::TypeDataStore.instance.library-id),
    #:app-id(library-id),
    :flags(G_APPLICATION_HANDLES_COMMAND_LINE),
    |c
  );
}

#-------------------------------------------------------------------------------
submethod BUILD ( *%options ) {

  # load the gtk resource file and register resource to make data global to app
  my Gnome::Gio::Resource $r .= new(:load(%?RESOURCES<library.gresource>.Str));
  $r.register;

  # startup signal fired after registration of app
  #self.register-signal( self, 'app-startup', 'startup');

  # fired after g_application_quit
  #self.register-signal( self, 'app-shutdown', 'shutdown');

  # fired to proces local options
  self.register-signal( self, 'local-options', 'handle-local-options');

  # fired to proces remote options
  self.register-signal( self, 'remote-options', 'command-line');

  # fired after g_application_run
  self.register-signal( self, 'build-gui', 'activate');

  # now we can register the application.
  my Gnome::Glib::Error $e = self.register;
  die $e.message if $e.is-valid;
}

#-------------------------------------------------------------------------------
method app-startup ( Gnome::Gtk3::Application :_widget($app) ) {
  # TODO init database?
}

#-------------------------------------------------------------------------------
method app-shutdown ( Gnome::Gtk3::Application :_widget($app) ) {
  # TODO save and cleanup database?
}

#-------------------------------------------------------------------------------
method local-options ( N-GObject $n-vd, :_widget($app) --> Int ) {
  # default continue app
  my Int $exit-code = -1;

  CATCH { default { .message.note; $exit-code = 1; return $exit-code; } }
  my Capture $o = get-options(
    |Library::App::TypeDataStore.instance.cmd-options
  );
  if $o<version> {
    my Library::App::TypeDataStore $tds .= instance;
    note "Version of Library; $tds.version()";
    $exit-code = 0;
  }

#  note "return with $exit-code\n";
  $exit-code
}

#-------------------------------------------------------------------------------
method remote-options ( N-GObject $n-cl,  :_widget($app) --> Int ) {
  my Int $exit-code = 0;
  my Gnome::Gio::ApplicationCommandLine $cl .= new(:native-object($n-cl));

  my Library::App::TypeDataStore $tds .= instance;
  $tds.set-arguments($cl.get-arguments);
#  $Library::app-config<arguments> = $cl.get-arguments;
#note 'args: ', $Library::app-config<arguments>;

# temporary test option
  my Capture $o = get-options-from(
    Library::App::TypeDataStore.instance.arguments[1..*-1],
    |Library::App::TypeDataStore.instance.cmd-options
  );

  $tds.set-project($o.<project>) if ?$o.<project>;

#  $Library::app-config<project> = $o.<project> if ?$o.<project>;
#  $Library::app-config<library-id> = library-id;
#note 'cfg: ', $Library::app-config;

  self.activate unless $cl.get-is-remote;

#`{{
# temporary test option
  my Str $file-to-show = $o.<show> if ($o.<show> // '') and $o.<show>.IO.r;
  if ?$file-to-show {
    $cl.print("Buzzy showing text from $file-to-show\n");
    note "Must show $file-to-show now";
    #… show file in window …
  }
}}

  # if not cleared, remote keeps running!
  $cl.clear-object;

  $exit-code
}

#-------------------------------------------------------------------------------
# need gui then, build base
method build-gui ( Gnome::Gtk3::Application :_widget($application) ) {

#  require ::('Library::App::MainWindow');
  Library::App::MainWindow.new(:$application);
}
