use v6;

use GTK::Simple::NativeLib;
use NativeCall;

use GTK::Simple::Raw :DEFAULT;
use GTK::Simple::Widget;

#unit class GTK::Simple::Image does GTK::Simple::Widget;
unit package Library;


# from gtk-3.0/gtk/gtkenums.h
#`{{
GTK_ICON_SIZE_INVALID,            # Invalid size.
GTK_ICON_SIZE_MENU,               # Size appropriate for menus (16px).
GTK_ICON_SIZE_SMALL_TOOLBAR,      # Size appropriate for small toolbars (16px).
GTK_ICON_SIZE_LARGE_TOOLBAR,      # Size appropriate for large toolbars (24px)
GTK_ICON_SIZE_BUTTON,             # Size appropriate for buttons (16px)
GTK_ICON_SIZE_DND,                # Size appropriate for drag and drop (32px)
GTK_ICON_SIZE_DIALOG,             # Size appropriate for dialogs (48px)
}}
enum GtkIconSize is export
  < GTK_ICON_SIZE_INVALID GTK_ICON_SIZE_MENU GTK_ICON_SIZE_SMALL_TOOLBAR
    GTK_ICON_SIZE_LARGE_TOOLBAR GTK_ICON_SIZE_BUTTON GTK_ICON_SIZE_DND
    GTK_ICON_SIZE_DIALOG
  >;

sub gtk_image_new( )
    is native(&gtk-lib)
    is export(:image)
    returns GtkWidget
    {*}

sub gtk_image_new_from_resource( Str $path )
    is native(&gtk-lib)
    is export(:image)
    returns GtkWidget
    {*}

sub gtk_image_new_from_file( Str $path )
    is native(&gtk-lib)
    is export(:image)
    returns GtkWidget
    {*}

sub gtk_image_set_from_resource( GtkWidget $image, Str $path )
    is native(&gtk-lib)
    is export(:image)
    {*}

sub gtk_image_set_from_file( GtkWidget $image, Str $path )
    is native(&gtk-lib)
    is export(:image)
    {*}

sub gtk_image_set_from_icon_name(
  GtkWidget $image, Str $icon-name, int32 $icon-size
)   is native(&gtk-lib)
    is export(:image)
    {*}


class Image does GTK::Simple::Widget {

  multi submethod BUILD( Str :$file! ) {
    $!gtk_widget = gtk_image_new_from_file($file);
  }

  multi submethod BUILD( Str :$resource! ) {
    $!gtk_widget = gtk_image_new_from_resource($resource);
  }

  multi submethod BUILD( ) {
    $!gtk_widget = gtk_image_new( );
  }


  multi method set-image( Str :$file! ) {
    gtk_image_set_from_file( $!gtk_widget, $file);
  }

  multi method set-image( Str :$resource! ) {
    gtk_image_set_from_resource( $!gtk_widget, $resource);
  }

  multi method set-image( Str :$icon-name!, :$icon-size = GTK_ICON_SIZE_MENU ) {
    gtk_image_set_from_icon_name( $!gtk_widget, $icon-name, $icon-size);
  }
}
