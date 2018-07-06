#!/usr/bin/env perl6

use v6;

# need a sub and an enum to do some lower level stuff
use GTK::Simple::Raw :ALL;

use GTK::Simple::App;
use GTK::Simple::Button;
use GTK::Simple::CheckButton;
use GTK::Simple::Frame;
use GTK::Simple::Grid;
use GTK::Simple::HBox;
use GTK::Simple::Label;
use GTK::Simple::FileChooserButton;
use GTK::Simple::Menu;
use GTK::Simple::MenuBar;
use GTK::Simple::MenuItem;
use GTK::Simple::MenuToolButton;
use GTK::Simple::TextView;
use GTK::Simple::Toolbar;
use GTK::Simple::VBox;
use GTK::Simple::Window;

use Library::Image;

use Library;
use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;
use Library::MetaData::File;
use Library::MetaData::Directory;

use MongoDB;
use BSON::Document;
use IO::Notification::Recursive;

#-------------------------------------------------------------------------------
initialize-library();

#-------------------------------------------------------------------------------
class Gui { ... }
my Gui $gui .= new;

#-------------------------------------------------------------------------------
class Gui {

  has GTK::Simple::App $!app;
  has GTK::Simple::Window $!collect-dialog;
  has GTK::Simple::Window $!metadata-dialog;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!app .= new( :title("Meta Data Library"), :height(50), :width(180));

    my GTK::Simple::VBox $menu-bar-vbox = self.create-menu;
    my GTK::Simple::VBox $toolbar-vbox = self.create-toolbar;

    self.create-collect-dialog;
    self.create-edit-metadata-dialog;

    my GTK::Simple::Grid $main-grid .= new(
      [ 0, 0, 5, 1 ] => $menu-bar-vbox,
      [ 0, 1, 5, 1 ] => $toolbar-vbox,
    );

    $!app.set-content($main-grid);
    $!app.show-all;
    $!app.run;
  }

  #-----------------------------------------------------------------------------
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

  #-----------------------------------------------------------------------------
  method create-toolbar ( --> GTK::Simple::VBox ) {

    # See for icon https://developer.gnome.org/gtk3/stable/gtk3-Stock-Items.html
    my GTK::Simple::MenuToolButton $new-tb-bttn .= new(:icon(GTK_STOCK_NEW));
    $new-tb-bttn.clicked.tap: {
      $!collect-dialog.show;
    }

    my GTK::Simple::MenuToolButton $open-tb-bttn .= new(:icon(GTK_STOCK_OPEN));
    $open-tb-bttn.clicked.tap: {
      $!metadata-dialog.show;
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
    $toolbar.add-separator;

    $toolbar.pack
  }

  #-----------------------------------------------------------------------------
  method create-collect-dialog ( ) {

    #==[ file chooser button set to select a folder ]==
    my GTK::Simple::FileChooserButton $file-cb .= new:
      :title("Select file or directory"),
#      :action(GTK_FILE_CHOOSER_ACTION_OPEN);
      :action(GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);

    #==[ checkbuttons for options ]==
    my GTK::Simple::CheckButton $recursive-cbttn .= new: :label(
      "Recurse down tree"
    );
#    my GTK::Simple::CheckButton $tag-extract-cbttn .= new: :label(
#      "Tags from names"
#    );

    my GTK::Simple::TextView $tags-insert .= new;
    my GTK::Simple::TextView $tags-remove .= new;

    #==[ start collection button ]==
    my GTK::Simple::Button $collect-bttn .= new(:label<Collect>);
    $collect-bttn.clicked.tap: {
      my Str $file = $file-cb.file-name();
      note "Collect data from {$file // '-'} with;\n",
           "  recursive: $recursive-cbttn.status()\n",
           "  tag names: $tag-extract-cbttn.status()\n",
           "  insert tags: $tags-insert.text()\n",
           "  remove tags: $tags-remove.text()\n ";

      if ? $file {
        my Bool $recurse = $recursive-cbttn.status;
        $file = $file.IO.dirname if $recurse and $file.IO !~~ :d;

        self.collect-metadata(
          $file,
          :tags([$tags-insert.text.split(/[\s || <punct>]+/).List]),
          :drop-tags([$tags-remove.text.split(/[\s || <punct>]+/).List]),
          :$recurse,
          :extract-tags($tag-extract-cbttn.status()),
        );
      }
    };

    #==[ close dialog button ]==
    my GTK::Simple::Button $done-bttn .= new(:label<Done>);
    $done-bttn.clicked.tap: { $!collect-dialog.hide; };

    my GTK::Simple::Grid $dialog-grid .= new(
#      [ 0, 0, 4, 1] => GTK::Simple::Label.new(:text('Collect Control Options')),

      [ 2, 1, 1, 1] => $recursive-cbttn,
      [ 2, 2, 1, 1] => $tag-extract-cbttn,

      [ 1, 3, 1, 1] => GTK::Simple::Label.new(:text('Insert tags')),
      [ 2, 3, 2, 2] => $tags-insert,
      [ 1, 4, 1, 1] => GTK::Simple::Label.new(:text(' ')),

      [ 1, 5, 1, 1] => GTK::Simple::Label.new(:text('Remove tags')),
      [ 2, 5, 2, 2] => $tags-remove,
      [ 1, 6, 1, 1] => GTK::Simple::Label.new(:text(' ')),

      [ 1, 8, 2, 1] => $file-cb,
      [ 3, 8, 1, 1] => $collect-bttn,
      [ 4, 8, 1, 1] => $done-bttn,
    );

    my GTK::Simple::Frame $dialog-frame .= new(:title('Collect Control Options'));
    $dialog-frame.set-content($dialog-grid);

    $!collect-dialog .= new(:title("Collect dialog"));
    $!collect-dialog.set-content($dialog-frame);

    gtk_window_set_position( $!collect-dialog.WIDGET, GTK_WIN_POS_MOUSE);
  }

  #-----------------------------------------------------------------------------
  method create-edit-metadata-dialog ( ) {

#    my Library::Image $image1 .= new(
#      :file("")
#    );

#    my Library::Image $image2 .= new;
#    $image2.set-image(
#      :file("")
#    );

#    # icon names https://specifications.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html
#    my Library::Image $image3 .= new(
#      :icon-name<go-down>, :icon-size(GTK_ICON_SIZE_BUTTON)
#    );

    self.create-collect-dialog;

    my GTK::Simple::Grid $metadata-grid .= new(
#      [ 0, 0, 1, 1 ] => $image1,
#      [ 0, 1, 1, 1 ] => $image2,
#      [ 0, 2, 1, 1 ] => $image3,
    );


    $!metadata-dialog .= new(:title("Meta Data Edit Ddialog"));
    $!metadata-dialog.set-content($metadata-grid);

    gtk_window_set_position( $!metadata-dialog.WIDGET, GTK_WIN_POS_MOUSE);
  }

  #-----------------------------------------------------------------------------
  method select-file ( --> Str ) {

    my GTK::Simple::FileChooserButton $fcb .= new(:title("Select file or directory"));
    $fcb.file-name;
  }

  #-----------------------------------------------------------------------------
  method exit-app( :$widget ) {
    note $widget.perl;
    $!app.exit;
  }


  #-----------------------------------------------------------------------------
  # collect and store metadata about files and directories.
  method collect-metadata (
    Str:D $object,                # file or directory name
    Array :$tags = [],            # tags list to set
    Array :$drop-tags = [],       # tags list to remove
    Bool :$recurse = False,       # collect recursively
    Bool :$extract-tags = False,  # get tags from absolute path and filename
  ) {

    shell "library-tag.pl6 {$tags[*]}" if $tags.elems;
    shell "library-tag.pl6 {$drop-tags[*]} :drop" if $drop-tags.elems;

    my Str $r = $recurse ?? '--r' !! '';
    shell "library-file.pl6 $r $object" if ?$object;
#`{{
    my Library::MetaData::File $file-meta-object;
    my Library::MetaData::Directory $dir-meta-object;

    # Copy to rw-able array.
    my @files-to-process = $object,;
    if !@files-to-process {

      info-message("No files to process");
      exit(0);
    }

    while shift @files-to-process -> $file {

      # Process directories
      if $file.IO ~~ :d {

        # Alias to proper name if dir
        my $directory := $file;

        info-message("process directory '$directory'");

        $dir-meta-object .= new(:object($directory));
        $dir-meta-object.set-metameta-tags(
          $directory, :$extract-tags, :$tags, :$drop-tags
        );

        # recurse deeper in to this directory
        if $recurse {

          # only 'content' files no '.' or '..'
          my @new-files = dir( $directory).List>>.absolute;

          @files-to-process.push(|@new-files);
        }

        else {

          info-message("Skip directory $directory");
        }
      }

      # Process plain files
      elsif $file.IO ~~ :f {

        info-message("process file $file");

        $file-meta-object .= new(:object($file));
        $file-meta-object.set-metameta-tags(
          $file, :$extract-tags, :$tags, :$drop-tags
        );
      }

      # Ignore other type of files
      else {

        warn-message("File $file is ignored, it is a special type of file");
      }
    }
}}
  }
}
