use v6;

#-------------------------------------------------------------------------------
class Library::Gui::Tools:auth<github:MARTIMM> {

  #-----------------------------------------------------------------------------
  method glade-file ( :$which --> Str ) {
    %?RESOURCES{$which}.Str;
  }
}
