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
  multi submethod BUILD ( ) {
    $!mime .= new;
  }

  #-----------------------------------------------------------------------------
  # Set the default informaton for a file in the meta structure
  method specific-init-meta ( ) {

    # file accepted, set other meta data
    my Str $file = $!object.IO.basename;
    my Str $extension = $!object.IO.extension;
    my Str $path = $!object.IO.absolute;
    $path ~~ s/ '/'? $file $//;

    my BSON::Document $object-meta .= new;
    $object-meta<mime-type> =
      ($!mime.get-mimetype(:$extension) // {})<_id> // '';

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

    info-message("metadata set for $!object");
    debug-message($!meta-data.perl);
  }

  #-----------------------------------------------------------------------------
  # Update database with the data in the meta structure.
  # Returns result document with at least key field 'ok'
  method update-meta ( --> BSON::Document ) {

    # Get the metadata and search in database using count. It depends
    # on the existence of the file what to do.
    my BSON::Document $doc .= new: (:ok(1));
    my BSON::Document $query;

    # search file using all its meta data
    if self.is-in-db: (
      name => $!meta-data<name>,
      object-meta => (path => $!meta-data<path>,),
      object-meta => (meta-type => ~MT-File,),
      object-meta => (content-sha1 => $!meta-data<object-meta><content-sha1>,),
      object-meta => (hostname => $!meta-data<hostname>,),
    ) {

      # if file is found in db, we do not have to do anything
      info-message("File $!meta-data<name> found by name, path and content, no update");
    }

    # So if not found ...
    else {

      info-message(
        "file $!meta-data<name> not found by name, path and content"
      );

      # search again using name and content
      if self.is-in-db( $query .= new: (
          name => $!meta-data<name>,
          object-meta => (meta-type => ~MT-File,),
          object-meta => (
            content-sha1 => $!meta-data<object-meta><content-sha1>,
          ),
          object-meta => (hostname => $!meta-data<hostname>,),
        )
      ) {

        info-message("file $!meta-data<name> found by name and content");

        # get the documents
        for self.find(:criteria($query)) -> $d {

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

      # else search with path and content
      elsif self.is-in-db( $query .= new: (
          object-meta => (meta-type => ~MT-File,),
          object-meta => (path => $!meta-data<path>,),
          object-meta => (
            content-sha1 => $!meta-data<object-data><content-sha1>,
          ),
          object-meta => (hostname => $!meta-data<hostname>,),
        )
      ) {

        info-message("File $!meta-data<name> found by path and content");

        # Check first if file from this search has an existing file
        for self.find(:criteria($query)) -> $d {
#note "Found ", $d.perl;
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
      elsif self.is-in-db( $query .= new: (
          object-meta => (meta-type => ~MT-File,),
          object-meta => (
            content-sha1 => $!meta-data<object-data><content-sha1>,
          ),
          object-meta => (hostname => $!meta-data<hostname>,),
      )) {

        info-message("File $!meta-data<name> found by its content");

        # Check first if file from this search has an existing file
        for self.find(:criteria($query)) -> $d {
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
      elsif self.is-in-db( $query .= new: (
          name => $!meta-data<name>,
          object-meta => (meta-type => ~MT-File,),
          object-meta => (path => $!meta-data<path>,),
          object-meta => (hostname => $!meta-data<hostname>,),
      )) {

        info-message("File $!meta-data<name> found by name and path");

        # Check first if file from this search has an existing file
        for self.find(:criteria($query)) -> $d {
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
        info-message("$!meta-data<name> not found -> must be new, updated");

        $doc = self.insert: [$!meta-data];
      }
    }

    # return database operations result
    $doc
  }
}
