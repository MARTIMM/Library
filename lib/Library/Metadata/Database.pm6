use v6.c;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;
use Library::Database;
use Library::MetaData::Object::File;

use BSON::Document;

#-------------------------------------------------------------------------------
# Class using Database role to handle specific database and collection
class Metadata::Database does Library::Database {

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    my Library::Configuration $lcg = $Library::lib-cfg;

    $lcg.config<database> = 'Library' unless ?$lcg.config<database>;
    $lcg.config<collection><meta-data> = 'meta-data'
      unless ?$lcg.config<meta-data>;
    $lcg.save;

    self.init( :database-key<database>, :collection-key<meta-data>);
  }

  #-----------------------------------------------------------------------------
  method update( Str $object, ObjectType $type ) {

    my BSON::Document $d .= new;

    given $object-type {
      when OT-File {

        my Library::MetaData::Object::File $o .= new( :$object, :$type);
        $d = $o.meta;
      }
    }

    callwith([$d,]);
  }
}

