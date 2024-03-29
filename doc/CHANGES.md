## Release notes

* 2021-03-24 0.14.1
  * Separated a MainWindow from gui.
  * Added local and remote option processing.
  * Separated XML files in resources file.
  * File menu becomes Application menu.

* 2020-12-03 0.14.0
  * Application is now build using Gtk Application and ApplicationWindow. The menus come from an XML file.
    * File menu quit.
    * Help menu about.
  * Re-design what needs to be on screen and how to activate it.

* 2019-05-02 0.13.5
  * Add Gui::Search
  * Refactored Gui::GatherData and Gui::Config from Gui::Main.

* 2019-05-01 0.13.4
  * Connect button in toolbar

* 2019-04-30 0.13.3
  * Bugfixed; when taglist or skiplists were empty, it was not possible to add a new entry. The update used here needed an `upsert => True`.

* 2019-04-30 0.13.2
  * Bugfix in saving meta data on a file. Some fields are not tested and might change also by previous bugs perhaps. Also new fields might be added later and must be saved too when same file/directory is scanned again.

* 2019-04-27 0.13.1
  * Config setup changes

* 2019-03-07 0.13.0
  * Added a connection dialog to connect to a server

* 2019-02-25 0.12.0
  Added a file chooser dialog to select files for database insertion
  <img src="Manual/Images/file-search-dialog.png" width="480" />

* 2019-02-11 0.11.1
  * Changes for using GTK::V3

* 2019-01-24 0.11.0
  * The graphical user interface can now show the tag filter list and skip data list.
  * Added dialogs and moved filter frames into dialog.
  <img src="Manual/Images/about-dialog.png" width="310" />
  * Set a logo on the about dialog.
  * Tags- and skip-filter now now possible to refresh, add new items or delete them.
  <img src="Manual/Images/tag-filter-dialog.png" width="200" />

* 2019-01-13 0.10.2
  * Bugfixes

* 2019-01-07 0.10.1
  * Started to create a new graphical user interface using Gnome::Gtk3::Glade
  <img src="Manual/Images/main-window.png" width="200" />

* 0.10.0
  * moved some fields from top level into object-meta
* 0.9.4
  * mimetype data is now in a resources file
  * some configuration entries are now fixed;
    ```
    [ library.collections.root ]
      mimetypes           = "Mimetypes"
      extensions          = "Extensions"
    [ library ]
      root-db             = "Library"
    ```
* 0.9.3 Added --getx to mime program
* 0.9.2 Mimetype program renamed to library-mimetype.pl6. Can do --add, --mod, --rem, --get and --install.
* 0.9.1 Addition of methods to module Mimetypes.
* 0.9.0 New module for class Library::MetaConfig::Mimetypes
* 0.8.5
  * Refactoring code from store-file-metadata.pl6 to library-skip.pl6
  * Renamed store-file-metadata.pl6 to library-file.pl6
  * Improved programs and modules
  * Bug fixes in programs library-tag.pl6 and library-skip.pl6
* 0.8.4
  * MetaConfig:: * files renamed.
  * Rename MetaData:: * files and change module structure.
* 0.8.3
  * Refactoring code from store-file-metadata.pl6 to library-tag.pl6
  * Renaming modules
  * Adding new tests
* 0.8.2
  * removal of modules, rename modules and configuration changes
* 0.8.1
  * Configuration rewrite and rename from config.toml into client-confguration.toml.
  * Rename Library::Metadata::Database into Library::Metadata::MainStore. Now it is better set for future storages.
* 0.8.0
  * Creating a gui based on GTK::Simple
* 0.7.0
  * Create class Library::Config::SkipList to manage filters for files and directories. Maybe also for other type of objects.
  * Renamed Library::ConfigTags to Library::Config::Tags
* 0.6.0
  * store-file-metadata.pl6 can now add tags in the user meta sub document of a given entry. Bsides adding it can also remove tags and filter against a list. This list is maintained by Library::ConfigTags. The program can deliver this information. The interface is now;
  ```
  Usage:
    store-file-metadata.pl6 [--dt=<Str>] tag-filter '[<filter-list> ...]'
    store-file-metadata.pl6 [-r] [-t=<Str>] [--et] [--dt=<Str>] fs '[<files> ...]'
  ```
  Tags are filtered against a list from the config collection.
* 0.5.3
  * Many modules rewritten and bugs fixed
  * Program store-file-metadata.pl6 is now functional
* 0.5.2
  * Metadata gathering for MT-Directory implemented.
* 0.5.1
  * work on store-file-metadat.pl6
* 0.5.0
  * Added Object, Object-file, Object-directory
* 0.4.0
  * Rewrite of Library::Configuration.
  * Rewrite of Library.
  * Add Library::Database role. Does the common operations like insert, update, delete and drop.
  * Rewrite of Library::Metadata::Database. It is a class which does the role Library::Database. Controls a specific database and collection for the operations and adds fields to documents depending on object type.
  * tests
* 0.3.0
  * Added keyword processing to store-file-metadata.pl6 and
    File-metadata-manager.pm6
  * Install-mimetypes.pl6 changed to store fileext as an array of extensions.
* 0.2.1
  * Bugfixes in File-metadata-manager
  * Bugfixes updating entries.
* 0.2.0
  * Added install-mimetypes.pl6
* 0.1.1
  * Modified modules and finished store-file-metadata.pl6
* 0.1.0
  * Creation date. Lots of thinking.
