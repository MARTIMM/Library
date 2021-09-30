use v6;

#-------------------------------------------------------------------------------
use Gnome::N::N-GObject;

use Gnome::Glib::Error;
use Gnome::Glib::VariantType;

use Gnome::Gdk3::Pixbuf;
use Gnome::Gdk3::Screen;

use Gnome::Gtk3::Builder;
use Gnome::Gtk3::ApplicationWindow;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
#use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::AboutDialog;

use Gnome::Gio::MenuModel;
use Gnome::Gio::SimpleAction;

use Library::App::TypeDataStore;

#use Library::Gui::QA::DBConfig;
use Library::Gui::OkMsgDialog;

#use Library::DB::Filter;
#use Library::DB::Client;
use Library::DB::Context;

#use BSON::Document;

use QA::Types;

#use Library::App::Menu::Help;
#use QAManager::App::Page::Category;
#use QAManager::App::Page::Sheet;
#use QAManager::App::Page::Set;

#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class Library::App::MainWindow:auth<github:MARTIMM>:ver<0.3.0>;
also is Gnome::Gtk3::ApplicationWindow;

has $!application is required;
has Gnome::Gtk3::Builder $!builder;
has Str $app-rbpath;
has Version $!app-version;
#has Str $!library-id;

#has Library::DB::Client $!db;
has Library::DB::Context $!db-context;

#enum NotebookPages <SHEETPAGE CATPAGE SETPAGE>;

#has Library::App::ApplicationWindow $!app-window;
has Gnome::Gtk3::Grid $!grid;
#has Gnome::Gtk3::Notebook $!notebook;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk3::ApplicationWindow class process the options
  self.bless( :GtkApplicationWindow, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( :$!application ) {

  $!db-context .= new;

  $!app-rbpath = $!application.get-resource-base-path;

  $!builder .= new;
  self.load-gui;

  self.setup-application-menu;
  self.setup-application-style;

  self.set-title('Library');
  self.set-border-width(2);
  self.set-keep-above(True);
#  self.set-position(GTK_WIN_POS_MOUSE);
  self.set-size-request( 400, 450);

  my Gnome::Glib::Error $e = self.set-icon-from-file(
    %?RESOURCES<library-logo.png>.Str
#    'Old/I/window-icon2.jpg'
  );
  die $e.message if $e.is-valid;

  $!grid .= new;
  self.add($!grid);

  self.show-all;
}

#-------------------------------------------------------------------------------
method load-gui ( ) {
  my Gnome::Glib::Error $e;

  # read the menu xml into the builder
  $e = $!builder.add-from-resource("$!app-rbpath/app-menu");
  die $e.message if $e.is-valid;

  # read the menu xml into the builder
  $e = $!builder.add-from-resource("$!app-rbpath/help-about");
  die $e.message if $e.is-valid;
}

#-------------------------------------------------------------------------------
method setup-application-style ( ) {

  # read the style definitions into the css provider and style context
  my Gnome::Gtk3::CssProvider $css-provider .= new;
  $css-provider.load-from-resource("$!app-rbpath/library-style");
#note 'scc v: ', $css-provider.is-valid;

  my Gnome::Gtk3::StyleContext $style-context .= new;
  $style-context.add_provider_for_screen(
    Gnome::Gdk3::Screen.new, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );
}

#-------------------------------------------------------------------------------
method setup-application-menu ( ) {

  # add application menu from XML in resources
  my Gnome::Gio::MenuModel $menubar .= new(:build-id<menubar>);
  $!application.set-menubar($menubar);

  self.link-actions(
    %( :quit<app-quit>,
       :about-dialog<help-about>,
#       :edit-db-config<db-config>,
       :edit-filters($!db-context),
       :pre-process-docs($!db-context),
       :connect($!db-context),
       :disconnect($!db-context),
#       :connect-db<connect-db>,
#       :disconnect-db<disconnect-db>,
    )
  );
  #self.link-state-action( 'select-compression', 'uncompressed');
}

#-------------------------------------------------------------------------------
# all actions are linked to methods with same name
method link-actions ( Hash $actions ) {

  for $actions.keys -> $action {
    my Str $method;
    my $object = self;
    my Str $name;
#note $actions{$action}.WHAT;

    given $actions{$action} {
      when Bool {
        $method = $action;
        $name = self.^name;
      }

      when Str {
        $method = $actions{$action};
        $name = self.^name;
      }

      default {
        $method = $action;
        $object = $actions{$action};
        $name = $object.^name;
        next unless $object.^can($method);
      }
    }

note "Map action $action.fmt('%-20.20s') ~~~> $name\.$method\()";

    my Gnome::Gio::SimpleAction $simple-action .= new(:name($action));
    $simple-action.set-enabled(True);
    $!application.add-action($simple-action);
    $simple-action.register-signal( $object, $method, 'activate');
    $simple-action.clear-object;
  }
}

#-------------------------------------------------------------------------------
method link-state-action (
  Str:D $action, Str:D :$state!, Str :$method is copy
) {
  $method //= $action;
#note "Map action $action.fmt('%-20.20s') with state $state ~~~> .$method\()";

  my Gnome::Gio::SimpleAction $simple-action;
  $simple-action .= new(
    :name($action),
    :parameter-type(Gnome::Glib::VariantType.new(:type-string<s>)),
    :state(Gnome::Glib::Variant.new(:parse("'$state'")))
  );
  $simple-action.register-signal( self, $method, 'change-state');
  $!application.add-action($simple-action);
  $simple-action.clear-object;
}

#-------------------------------------------------------------------------------
method link-action ( Str:D $action, Str :$method is copy ) {

  $method //= $action;
#note "Map action $action.fmt('%-20.20s') ~~~> .$method\()";

  my Gnome::Gio::SimpleAction $simple-action;
  $simple-action .= new(:name($action));
  $simple-action.register-signal( self, $method, 'activate');
  $!application.add-action($simple-action);
  $simple-action.clear-object;
}

#--[ signal handlers ]----------------------------------------------------------

#-- [ menu ] -------------------------------------------------------------------
# Application > Quit
method app-quit ( N-GObject $n-parameter ) {
#  note "Selected 'Quit' from 'Application' menu";

  $!application.quit;
}

#`{{
#-------------------------------------------------------------------------------
# Database > Configure database
method db-config ( N-GObject $n-parameter ) {
  note "Selected 'Configure database' from 'Application' menu";
  my Library::Gui::QA::DBConfig $df .= new(:sheet-name<client-config>);

  my Hash $db-config = $df.show-dialog;
  note $db-config.gist;
}
}}

#-------------------------------------------------------------------------------
# Help > About
method help-about ( N-GObject $n-parameter ) {
#  CONTROL { when CX::Warn {  note .gist; .resume; } }
#  note "Selected 'About' from 'Help' menu";
  my Gnome::Gtk3::AboutDialog $about .= new(:build-id<aboutdialog>);
  $about.set-transient-for(self);
  $about.set-version(Library::App::TypeDataStore.instance.version.Str);

  # Getting some ideas to show different UML images of what program does.
  # Using some scratch images now…
  my Gnome::Gdk3::Pixbuf $pix .= new(
#    :file("Old/I/p{9.rand.Int}.jpg"), :width(450), :height(450)
    :file(%?RESOURCES<library-logo.png>.Str), :width(100), :height(100)
  );
  $about.set-logo($pix);
  $about.run;
  $about.hide;  # cannot destroy, builder keeps same native-object
}

#-------------------------------------------------------------------------------
# show message
method !show-msg($message) {
  my Library::Gui::OkMsgDialog $msg-diag .= new(
    :message('Warning'), :secondary-message($message)
  );
  $msg-diag.run;
  $msg-diag.destroy;
}

=finish




  # make main window widgets
  #my Gnome::Gtk3::Grid $grid .= new;
  #self.add($grid);

  #my Gnome::Gtk3::Grid $fst-page = self.setup-workarea;
  #self.setup-workarea;

#Gnome::N::debug(:on);

  # set the visibility of the menu after all is shown
#  self.set-menu-visibility( 'sheet', :visible);
#  self.set-menu-visibility( 'category', :!visible);
#  self.set-menu-visibility( 'set', :!visible);


#`{{
  my Gnome::Gtk3::Label $strut .= new(:text(''));
  $strut.set-line-wrap(False);
  #$description.set-max-width-chars(60);
  $strut.set-justify(GTK_JUSTIFY_FILL);
  $strut.widget-set-halign(GTK_ALIGN_START);

  my Gnome::Gtk3::MenuBar $mb .= new(:build-id<menubar>);
  $!grid.grid-attach( $mb, 0, 0, 1, 1);

  my $app := self;

  my Library::App::Menu::File $file .= new(:$app);
  my Library::App::Menu::Help $help .= new(:$app);

  my Hash $handlers = %(
    :file-quit($file),
    :help-about($help),
  );

  $builder.connect-signals-full($handlers);
}}

#`{{
#-------------------------------------------------------------------------------
# register a handler for a menu item. The $build-id is also the name
# of the handler method in the $menu object.
method menu-handler ( $menu, $build-id ) {

  my Gnome::Gtk3::MenuItem $mi .= new(:$build-id);
  $mi.register-signal( $menu, $build-id, 'activate');
}
}}

#-------------------------------------------------------------------------------
#`{{
method setup-workarea ( --> Gnome::Gtk3::Grid ) {
  $!notebook .= new;
  $!notebook.widget-set-hexpand(True);
  $!notebook.widget-set-vexpand(True);

  my $app := self;
  my QAManager::App::Page::Sheet $sheet .= new;
  $!notebook.append-page( $sheet, Gnome::Gtk3::Label.new(:text<Sheets>));

  $!notebook.append-page(
    QAManager::App::Page::Category.new,
    Gnome::Gtk3::Label.new(:text<Categories>)
  );

  $!notebook.append-page(
    QAManager::App::Page::Set.new(
      :$app, :$!app-window, :rbase-path(self.get-resource-base-path)
    ),
    Gnome::Gtk3::Label.new(:text<Sets>)
  );

#  $!notebook.register-signal( self, 'change-menu', 'switch-page');
  $!grid.grid-attach( $!notebook, 0, 1, 1, 1);

  # return one of the pages to set the visibility of the menu after all is shown
  $sheet
}
}}

#`{{
#-------------------------------------------------------------------------------
method set-menu-visibility( Str $menu-id, Bool :$visible ) {
  my Gnome::Gtk3::MenuItem $menu .= new(:build-id($menu-id));
  $menu.set-visible($visible);
}
}}

#--[ signal handlers ]----------------------------------------------------------
#`{{
# change menu on change of notebook pages
method change-menu ( N-GObject $no, uint32 $page-num --> Int ) {

  given $page-num {
    when SHEETPAGE {
      self.set-menu-visibility( 'sheet', :visible);
      self.set-menu-visibility( 'category', :!visible);
      self.set-menu-visibility( 'set', :!visible);
    }

    when CATPAGE {
      self.set-menu-visibility( 'sheet', :!visible);
      self.set-menu-visibility( 'category', :visible);
      self.set-menu-visibility( 'set', :!visible);
    }

    when SETPAGE {
      self.set-menu-visibility( 'sheet', :!visible);
      self.set-menu-visibility( 'category', :!visible);
      self.set-menu-visibility( 'set', :visible);
    }
  }

  1;
}
}}
