use v6;

#-------------------------------------------------------------------------------
unit class Library::Gui::Tools:auth<github:MARTIMM>;

#-----------------------------------------------------------------------------
method glade-file ( :$which --> Str ) {
  %?RESOURCES{$which}.Str;
}
