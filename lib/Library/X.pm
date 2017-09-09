use v6;

#------------------------------------------------------------------------------
class X::Library is Exception {
  has $.message;

  submethod BUILD ( :$!message ) { }
}
