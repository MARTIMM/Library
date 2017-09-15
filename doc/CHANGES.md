## Release notes

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
  * Metadata gathering for OT-Directory implemented.
* 0.5.1
  * work on store-file-metadat.pl6
* 0.5.0
  * Added Object, Object-file, Object-directory
* 0.4.0
  * Rewrite of Library::Configuration.
  * Rewrite of Library.
  * Add Library::Database role. Does the common operations like insert, update, delete and drop.
  * Rewrite of Library::Metadata::Database. It is class which does the role Library::Database. Controls a specific database and collection for the operations and adds fields to documents depending on object type.
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
