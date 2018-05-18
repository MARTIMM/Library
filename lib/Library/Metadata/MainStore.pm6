use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

use Library;
use Library::Configuration;
use Library::Database;

use MongoDB;

#-------------------------------------------------------------------------------
# Class using Database role to handle specific database and collection
class Metadata::MainStore does Library::Database {

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    self.init( :database-key<database>, :collection-key<meta-data>);
  }
}
