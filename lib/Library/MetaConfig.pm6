use v6;

#-------------------------------------------------------------------------------
unit package Library:auth<github:MARTIMM>;

#use Library;
use Library::Storage;

#-------------------------------------------------------------------------------
role MetaConfig {

  has Library::Storage $!dbcfg;

  # alternative database/collection pairs
  has Library::Storage $!dbcfg1;
  has Library::Storage $!dbcfg2;
  has Library::Storage $!dbcfg3;
  has Library::Storage $!dbcfg4;
  has Library::Storage $!dbcfg5;

  #-----------------------------------------------------------------------------
  proto BUILD ( Bool :$root = False ) {*}
  multi submethod BUILD ( Bool :$root = False ) {

    $!dbcfg .= new( :collection-key<meta-config>, :$root);

    # call other BUILDs when there are any
    callsame;
  }
}
