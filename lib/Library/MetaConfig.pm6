use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#use Library;
use Library::Storage;

#-------------------------------------------------------------------------------
role MetaConfig {

  has Library::Storage $!dbcfg;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Bool :$root = False ) {

    $!dbcfg .= new( :collection-key<meta-config>, :$root);
  }
}
