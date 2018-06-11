use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#use Library;
use Library::Storage;

#-------------------------------------------------------------------------------
role MetaConfig {

  has Library::Storage $!dbcfg;

  #-----------------------------------------------------------------------------
  proto BUILD ( Bool :$root = False ) {*}
  multi submethod BUILD ( Bool :$root = False ) {

    $!dbcfg .= new( :collection-key<meta-config>, :$root);

    # call other BUILDs when there are any
    callsame;
  }
}
