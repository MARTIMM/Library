#!/usr/bin/env perl6

use v6;

# need a sub and an enum to do some lower level stuff
use GTK::Simple::Raw :ALL;

use GTK::Simple::App;
use GTK::Simple::Button;
use GTK::Simple::Frame;
use GTK::Simple::HBox;
use GTK::Simple::VBox;
use GTK::Simple::FileChooserButton;
use GTK::Simple::CheckButton;
use GTK::Simple::Toolbar;
use GTK::Simple::MenuToolButton;
use GTK::Simple::MenuBar;
use GTK::Simple::Menu;
use GTK::Simple::MenuItem;
use GTK::Simple::Window;

#------------------------------------------------------------------------------
class Gui { ... }
my Gui $gui .= new;

#------------------------------------------------------------------------------
class Gui {

  has GTK::Simple::App $!app;
  has GTK::Simple::Window $!collect-dialog;

  #----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!app .= new( :title("Meta Data Library"), :height(100), :width(200));

    my GTK::Simple::VBox $menu-bar-vbox = self.create-menu;
    my GTK::Simple::VBox $toolbar-vbox = self.create-toolbar;

    self.create-collect-dialog;

    my GTK::Simple::VBox $vbox .= new(
      [ $menu-bar-vbox,
        { :widget($toolbar-vbox),
          :expand(False)
        },
#        { :widget($file-cb),
#          :expand(False)
#        }
      ]
    );


    $!app.set-content($vbox);
    $!app.show-all;
    $!app.run;
  }

  #----------------------------------------------------------------------------
  method create-menu ( --> GTK::Simple::VBox ) {

    # 'File' menu
    my GTK::Simple::MenuItem $file-menu-item .= new(:label<File>);

    # with a 'Collect' menu item
    my GTK::Simple::MenuItem $collect-menu-item .= new(:label<Collect>);
    $collect-menu-item.activate.tap: -> $widget {
      $!collect-dialog.show;
    }

    # with a 'Quit' menu item
    my GTK::Simple::MenuItem $quit-menu-item .= new(:label("Quit"));
    $quit-menu-item.activate.tap: -> $widget {
      self.exit-app(:$widget);
    }

    # make the menu
    my GTK::Simple::Menu $file-menu .= new;
    $file-menu-item.set-sub-menu($file-menu);
    $file-menu.append($collect-menu-item);
    $file-menu.append($quit-menu-item);


    # 'Help' menu
    my GTK::Simple::MenuItem $help-menu-item .= new(:label("Help"));

    # with an 'About' menu item
    my GTK::Simple::MenuItem $about-menu-item .= new(:label("About"));
    $about-menu-item.activate.tap: -> $widget {
      note "F: ", self.select-file();
    }

    # make the menu
    my GTK::Simple::Menu $help-menu .= new;
    $help-menu-item.set-sub-menu($help-menu);
    $help-menu.append($about-menu-item);


    my GTK::Simple::MenuBar $menu-bar .= new;
    $menu-bar.append($file-menu-item);
    $menu-bar.append($help-menu-item);

    $menu-bar.pack
  }

  #----------------------------------------------------------------------------
  method create-toolbar ( --> GTK::Simple::VBox ) {

    # See for icon https://developer.gnome.org/gtk3/stable/gtk3-Stock-Items.html
    my GTK::Simple::MenuToolButton $new-tb-bttn .= new(:icon(GTK_STOCK_NEW));
    $new-tb-bttn.clicked.tap: {
      "New toolbar button clicked".say;
    }

    my GTK::Simple::MenuToolButton $open-tb-bttn .= new(:icon(GTK_STOCK_OPEN));
    $open-tb-bttn.clicked.tap: {
      "Open toolbar button clicked".say;
    }

    my GTK::Simple::MenuToolButton $save-tb-bttn .= new(:icon(GTK_STOCK_SAVE));
    $save-tb-bttn.clicked.tap: {
      "Save toolbar button clicked".say;
    }

    my GTK::Simple::MenuToolButton $exit-tb-bttn .= new(:icon(GTK_STOCK_QUIT));
    $exit-tb-bttn.clicked.tap: -> $widget {
      self.exit-app(:$widget);
    }

    my GTK::Simple::Toolbar $toolbar .= new;
    $toolbar.add-menu-item($new-tb-bttn);
    $toolbar.add-menu-item($open-tb-bttn);
    $toolbar.add-menu-item($save-tb-bttn);
    $toolbar.add-separator;
    $toolbar.add-menu-item($exit-tb-bttn);

    $toolbar.pack
  }

  #----------------------------------------------------------------------------
  method create-collect-dialog ( ) {

    my GTK::Simple::FileChooserButton $file-cb .= new:
      :title("Select file or directory"),
      :action(GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER)
      ;
#    $file-cb.file-set.tap: {
#      note $file-cb.file-name;
#    };

    my GTK::Simple::CheckButton $recursive-cbttn .= new: :label("Recurse down tree");
    my GTK::Simple::CheckButton $tagsfname-cbttn .= new: :label("Tags from names");

    my GTK::Simple::VBox $vbox-cbttns .= new;
    $vbox-cbttns.spacing(2);
    $vbox-cbttns.pack-start( $recursive-cbttn, False, False, 2);
    $vbox-cbttns.pack-start( $tagsfname-cbttn, False, False, 2);

    my GTK::Simple::Frame $frame-cbttns .= new(:label("Options"));
    $frame-cbttns.set-content($vbox-cbttns);



    my GTK::Simple::Button $collect-bttn .= new(:label<Collect>);
    $collect-bttn.clicked.tap: {
      note "Collect data from $file-cb.file-name()";
    };

    my GTK::Simple::Button $done-bttn .= new(:label<Done>);
    $done-bttn.clicked.tap: { $!collect-dialog.hide; };

    my GTK::Simple::HBox $hbox .= new;
    $hbox.spacing(2);
    $hbox.pack-start( $collect-bttn, False, False, 2);
    $hbox.pack-start( $done-bttn, False, False, 2);

    my GTK::Simple::VBox $vbox .= new;
    $vbox.pack-start( $frame-cbttns, False, False, 2);
    $vbox.pack-start( $file-cb, False, False, 2);
    $vbox.pack-start( $hbox, False, False, 2);

    my GTK::Simple::Frame $frame .= new(:label("Collect control settings"));
    $frame.set-content($vbox);

    $!collect-dialog .= new(:title("Collect dialog"));
    $!collect-dialog.set-content($frame);

    gtk_window_set_position( $!collect-dialog.WIDGET, GTK_WIN_POS_MOUSE);
  }

  #----------------------------------------------------------------------------
  method select-file ( --> Str ) {

    my GTK::Simple::FileChooserButton $fcb .= new(:title("Select file or directory"));
    $fcb.file-name;
  }

  #------------------------------------------------------------------------------
  method exit-app( :$widget ) {
    note $widget.perl;
    $!app.exit;
  }
}
