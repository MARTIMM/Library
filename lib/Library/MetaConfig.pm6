use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#use Library;
use Library::Storage;

#-------------------------------------------------------------------------------
role MetaConfig {

  has Library::Storage $!dbcfg .= new(:collection-key<meta-config>);

  # alternative database/collection pairs
  has Library::Storage $!dbcfg1;
  has Library::Storage $!dbcfg2;
  has Library::Storage $!dbcfg3;
  has Library::Storage $!dbcfg4;
  has Library::Storage $!dbcfg5;
}
