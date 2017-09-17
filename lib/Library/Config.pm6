use v6;

#------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#use Library;
use Library::Database;

#------------------------------------------------------------------------------
role Config {

  has Library::Database $!dbcfg;

  #----------------------------------------------------------------------------
  submethod BUILD ( ) {

    # use role as a class. initialize with database and collection
    $!dbcfg .= new;
    $!dbcfg.init( :database-key<database>, :collection-key<meta-config>);
  }
}
