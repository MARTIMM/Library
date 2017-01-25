use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;
use Library::Database;
use Library::Metadata::Object;
use Library::Metadata::Object::File;
use Library::Metadata::Object::Directory;

use MongoDB;

#-------------------------------------------------------------------------------
# Class using Database role to handle specific database and collection
class Metadata::Database does Library::Database {

  has Library::Metadata::Object $!meta-object;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    my Library::Configuration $lcg = $Library::lib-cfg;

    $lcg.config<database> = 'Library' unless ?$lcg.config<database>;
    $lcg.config<collection><meta-data> = 'Metadata'
      unless ?$lcg.config<collection><meta-data>;
    $lcg.save;

    self.init( :database-key<database>, :collection-key<meta-data>);
  }

  #-----------------------------------------------------------------------------
  method update-meta(
    Str :$object, ObjectType :$type
    --> Library::Metadata::Object
  ) {

    # create object and generate metadata with the arguments
    given $type {
      when OT-File {

        $!meta-object = Library::Metadata::Object::File.new(
          :dbo(self), :$object, :$type
        );
      }

      when OT-Directory {

        $!meta-object = Library::Metadata::Object::Directory.new(
          :dbo(self), :$object, :$type
        );
      }

      default {
        fatal-message("Type $type not yet implemented");
      }
    }

    # modify database if needed
    my $doc = $!meta-object.update-meta;
#note "L::M::D: ", $doc.perl;

    $!meta-object;
  }
}

