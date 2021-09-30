#!/usr/bin/env -S raku -Ilib

use v6.d;
#use lib '../gnome-gtk3/lib';
use lib '../question-answer/lib';

use Library::App::Application;
use Library::App::TypeDataStore;

use QA::Types;

#-------------------------------------------------------------------------------
#our $Library::version = Version.new(v0.14.3);
#our $Library::options-filter = <version project:s>;
#our $Library::arguments = [];
#our $Library::app-config = %();

my Library::App::TypeDataStore $tds .= instance;
$tds.set-version(Version.new(v0.14.3));
$tds.set-cmd-options(<version project:s>);
$tds.set-library-id('io.github.martimm.library');

#-------------------------------------------------------------------------------
# let QA look at the proper locations
given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfg-root(Library::App::TypeDataStore.instance.library-id);
#  .cfg-root(library-id);
#    .list-dirs.note;
}

#-------------------------------------------------------------------------------
given my Int $exit-code = Library::App::Application.new.run // 1 {
  when 0 { }

  when 1 {
    show-usage;
  }

  default {
    note "Unknown error: $exit-code";
  }
}

exit($exit-code);

#-------------------------------------------------------------------------------
sub show-usage ( ) {
  note Q:q:to/EO-USAGE/;

  Library program. Used to gather document information from elsewhere after
  which the user can add meta information and link to other sources.

  Usage;
    library-gui [<Options>] [<Arguments>]

  Options;
    --version                         Show version of library and exit

  Arguments;
    project-name                      Section of userdata to select database
                                      and other information from application
                                      configuration.

  EO-USAGE
}









=finish
#!/usr/bin/env perl6

use v6;

#use lib
#        '/home/marcel/Languages/Perl6/Projects/perl6-gnome-native/lib',
#        '/home/marcel/Languages/Perl6/Projects/perl6-gnome-glade3/lib',
#        '/home/marcel/Languages/Perl6/Projects/perl6-gnome-gobject/lib',
#        '/home/marcel/Languages/Perl6/Projects/perl6-gnome-gtk3/lib',
#        '/home/marcel/Languages/Perl6/Projects/mongo-perl6-driver/lib',
#        ;

# Version of library
my Version $*version = v0.13.4;
my Bool $*debug = False;


use Library;
use Library::Tools;
use Library::Gui::Main;
use Library::Gui::FilterList;
use Library::Gui::Search;
use Library::Gui::Config;
use Library::Gui::GatherData;

use Gnome::Gtk3::Button;
use Gnome::Gtk3::Glade;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
#initialize-library(:refine-key<marcel>);
initialize-library();

#-------------------------------------------------------------------------------
sub MAIN ( Bool :$debug = False ) {

  my Library::Tools $tools .= new;
  my Str $ui-file = $tools.get-resource(:which<library.glade>);

  my Gnome::Gtk3::Glade $gui .= new;
  $gui.add-gui-file($ui-file);
  $gui.add-engine(Library::Gui::Main.new);
  $gui.add-engine(Library::Gui::FilterList.new);
  $gui.add-engine(Library::Gui::Search.new);
  $gui.add-engine(Library::Gui::Config.new);
  $gui.add-engine(Library::Gui::GatherData.new);

  $*debug = $debug;
  Gnome::N::debug(:on($debug));

  $gui.run;
}

#-------------------------------------------------------------------------------
sub USAGE ( ) {

  note Q:qq:to/EOUSAGE/;

    Usage:
      $*PROGRAM [<options>] <arguments>

    Options:

    Arguments:

  EOUSAGE
}
