#!/usr/bin/env perl6

use v6;

use GTK::Simple::App;
use GTK::Simple::Button;
use GTK::Simple::VBox;
use GTK::Simple::FileChooserButton;
use GTK::Simple::Toolbar;
use GTK::Simple::MenuToolButton;
use GTK::Simple::MenuBar;
use GTK::Simple::Menu;
use GTK::Simple::MenuItem;

#------------------------------------------------------------------------------
class Gui { ... }
my Gui $gui .= new;

#------------------------------------------------------------------------------
class Gui {

  has GTK::Simple::App $!app;

  has GTK::Simple::MenuBar $!menu-bar;
  has GTK::Simple::Menu $!file-menu;
  has GTK::Simple::MenuItem $!file-menu-item;
  has GTK::Simple::MenuItem $!quit-menu-item;
  has GTK::Simple::Menu $!command-menu;
  has GTK::Simple::MenuItem $!select-menu-item;
  has GTK::Simple::Menu $!help-menu;
  has GTK::Simple::MenuItem $!help-menu-item;
  has GTK::Simple::MenuItem $!about-menu-item;


  has GTK::Simple::Toolbar $!toolbar;
  has GTK::Simple::MenuToolButton $!new-tb-bttn;
  has GTK::Simple::MenuToolButton $!open-tb-bttn;
  has GTK::Simple::MenuToolButton $!save-tb-bttn;
  has GTK::Simple::MenuToolButton $!exit-tb-bttn;

  #----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!app .=  new( :title("Meta Data Library"), :height(100), :width(200));


    $!file-menu-item .= new(:label("File"));
    $!file-menu-item.set-sub-menu( $!file-menu .= new );

    $!quit-menu-item .= new(:label("Quit"));
    $!quit-menu-item.activate.tap: -> $widget {
      self.exit-app(:$widget);
    }

    $!file-menu.append($!quit-menu-item);


    $!select-menu-item .= new(:label("Select"));
    $!select-menu-item.set-sub-menu( $!command-menu .= new );
    $!select-menu-item.activate.tap: -> $widget {
      note "F: ", self.select-file();
    }

    $!menu-bar .= new;
    $!menu-bar.append($!file-menu-item);
    $!menu-bar.append($!select-menu-item);



    my GTK::Simple::VBox $menu-bar-vbox = $!menu-bar.pack;


    # See for icon https://developer.gnome.org/gtk3/stable/gtk3-Stock-Items.html
    $!new-tb-bttn .= new(:icon(GTK_STOCK_NEW));
    $!new-tb-bttn.clicked.tap: {
      "New toolbar button clicked".say;
    }

    $!open-tb-bttn .= new(:icon(GTK_STOCK_OPEN));
    $!open-tb-bttn.clicked.tap: {
      "Open toolbar button clicked".say;
    }

    $!save-tb-bttn .= new(:icon(GTK_STOCK_SAVE));
    $!save-tb-bttn.clicked.tap: {
      "Save toolbar button clicked".say;
    }

    $!exit-tb-bttn .= new(:icon(GTK_STOCK_QUIT));
    $!exit-tb-bttn.clicked.tap: -> $widget {
      self.exit-app(:$widget);
    }

    $!toolbar .= new;
    $!toolbar.add-menu-item($!new-tb-bttn);
    $!toolbar.add-menu-item($!open-tb-bttn);
    $!toolbar.add-menu-item($!save-tb-bttn);
    $!toolbar.add-separator;
    $!toolbar.add-menu-item($!exit-tb-bttn);

    my GTK::Simple::VBox $toolbar-vbox = $!toolbar.pack;

    my GTK::Simple::VBox $vbox .= new(
      [ $menu-bar-vbox,
        { :widget($toolbar-vbox),
          :expand(False)
        }
      ]
    );

    $!app.set-content($vbox);
    $!app.show-all;
    $!app.run;
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
