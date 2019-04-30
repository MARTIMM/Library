use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::MetaConfig::TagFilterList;
use Library::MetaConfig::SkipDataList;
use Library::MetaConfig::Mimetype;
use Library::MetaData;

use MongoDB;
use BSON::Document;

#-------------------------------------------------------------------------------
class MetaData::File does Library::MetaData {

  has Library::MetaConfig::Mimetype $!mime;

  #-----------------------------------------------------------------------------
  # Set the default informaton for a file in the meta structure
  method specific-init-meta ( ) {
#note "get spec meta";
    # file accepted, set other meta data
    my Str $path = $!object.IO.absolute;
    my Str $file = $path.IO.basename;
    my Str $extension = $file.IO.extension;

    # Drop basename from path
    $path ~~ s/ '/'? $file $//;

    $!mime .= new unless ?$!mime;
    my BSON::Document $object-meta .= new;
#note "empty meta: ", $object-meta.perl;
    $object-meta<mime-type> =
      ($!mime.get-mimetype(:$extension) // {})<_id> // '';
#note "meta: ", $object-meta.perl;

#    $object-meta<description> = $file-magic<description>;
#    $object-meta<mime-type> = $file-magic<mime-type>;
#    $object-meta<encoding> = $file-magic<encoding>;
#    $object-meta<mime-type-with-encoding> =
#      $file-magic<mime-type-with-encoding>;

    $object-meta<meta-type> = MT-File.Str;
    $object-meta<content-sha1> = self!sha1-content($!object);
    $object-meta<path> = $path;
    $object-meta<exists> = $!object.IO ~~ :r;
    $object-meta<hostname> = qx[hostname].chomp;

    $!meta-data<name> = $file;
    $!meta-data<object-meta> = $object-meta;

#note "File meta: ", $!meta-data.perl;
    info-message("metadata set for $!object");
    debug-message($!meta-data.perl);
  }

  #-----------------------------------------------------------------------------
  # Update database with the data in the meta structure.
  # Returns result document with at least key field 'ok'
  method update-meta ( --> BSON::Document ) {

#note "\nupdate meta: ", $!meta-data.perl;
    # Get the metadata and search in database using count. It depends
    # on the existence of the file what to do.
    my BSON::Document $doc .= new: (:ok(1));
    my BSON::Document $query;

    # search file using all its meta data.
    # keep in same order as stored!
    if ?($query = self.test-file: (
      name => $!meta-data<name>,
      "object-meta.meta-type" => ~MT-File,
      "object-meta.content-sha1" => $!meta-data<object-meta><content-sha1>,
      "object-meta.path" => $!meta-data<object-meta><path>,
      "object-meta.hostname" => $!meta-data<object-meta><hostname>,
    ) ) {

      # Update the record to modify any other non-tested but changed fields
      $doc = self.update: [ (
          q => $query,
          u => ( '$set' => $!meta-data,),
        ),
      ];

      self!log-update-message($doc);
    }

    # So if not found ...
    else {

      info-message(
        "file $!meta-data<name> not found by name, path and content"
      );

      # search again using name and content but not by path
#note "$!meta-data<name> not found: $!meta-data";
      if ?($query = self.test-file: (
        name => $!meta-data<name>,
        "object-meta.meta-type" => ~MT-File,
        "object-meta.content-sha1" => $!meta-data<object-meta><content-sha1>,
        "object-meta.hostname" => $!meta-data<object-meta><hostname>,
      ) ) {
note "Found 1...";#, $query;

        info-message("file $!meta-data<name> found by name and content");

        # get the documents
        for self.find($query) -> $d {
note "Found ", $d.perl;
          # check first if file in this document is also an existing file on disk
          # if it exists, the file is moved (same name and contant).
          # modify the record found in the query to set the new .
          if "$d<object-meta><path>/$d<name>".IO ~~ :e {

            info-message(
              "$!meta-data<name> found on disk elsewhere," ~
              " must have been moved, updated"
            );

# TODO What if query returns more of the same, is that possible?
# $query replace by data from $d
# $!meta-data replaces all data!?
            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            self!log-update-message($doc);
            last;
          }

# TODO when file not exists on disk .... what then?
          else {
          }
        }
      }

      # else search with path and content but not by name
      elsif ?($query = self.test-file: (
          "object-meta.meta-type" => ~MT-File,
          "object-meta.content-sha1" => $!meta-data<object-meta><content-sha1>,
          "object-meta.path" => $!meta-data<object-meta><path>,
          "object-meta.hostname" => $!meta-data<object-meta><hostname>,
      ) ) {
note "Found 2...";

        info-message("File $!meta-data<name> found by path and content");

        # Check first if file from this search has an existing file
        for self.find($query) -> $d {
note "Found ", $d.perl;
          if "$d<object-meta><path>/$d<name>".IO ~~ :e {
#!!!!!!
            info-message(
              "$!meta-data<name> found on disk elsewhere," ~
              " must have been renamed, updated"
            );

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            self!log-update-message($doc);
            last;
          }
        }
      }

      # else search for its content only
      elsif ?($query = self.test-file: (
          "object-meta.meta-type" => ~MT-File,
          "object-meta.content-sha1" => $!meta-data<object-meta><content-sha1>,
          "object-meta.hostname" => $!meta-data<object-meta><hostname>,
      ) ) {
note "Found 3...";

        info-message("File $!meta-data<name> found by its content");

        # Check first if file from this search has an existing file
        for self.find($query) -> $d {
          if "$d<object-meta><path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been renamed and moved, updated");

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            self!log-update-message($doc);
            last;
          }
        }
      }

      # else search for name and path
      elsif ?($query = self.test-file: (
          name => $!meta-data<name>,
          "object-meta.meta-type" => ~MT-File,
          "object-meta.path" => $!meta-data<object-meta><path>,
          "object-meta.hostname" => $!meta-data<object-meta><hostname>,
      ) ) {
note "Found 4...";

        info-message("File $!meta-data<name> found by name and path");

        # Check first if file from this search has an existing file
        for self.find($query) -> $d {
          if "$d<object-meta><path>/$d<name>".IO ~~ :e {

            info-message("$!meta-data<name> found on disk elsewhere, must have been modified or deleted, updated");

            # Update the record to reflect current situation
            $doc = self.update: [ (
                q => $query,
                u => ( '$set' => $!meta-data,),
              ),
            ];

            self!log-update-message($doc);
            last;
          }
        }
      }

      # different file
      else {
note "Found 5...";
        info-message("$!meta-data<name> not found -> must be new, updated");

        $doc = self.insert: [$!meta-data];
      }
    }

    # return database operations result
    $doc
  }

  #-----------------------------------------------------------------------------
  method test-file ( List $list --> BSON::Document ) {

#note "called from: ", callframe(1);
#note "Meta: $!meta-data";
#note "List: ", $list.perl;

    my BSON::Document $q .= new: (|$list);
    self.is-in-db($q) ?? $q !! BSON::Document
  }
}
