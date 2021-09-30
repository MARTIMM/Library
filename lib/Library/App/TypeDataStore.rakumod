use v6;

#-------------------------------------------------------------------------------
unit class Library::App::TypeDataStore:auth<github:MARTIMM>:ver<0.1.0>;

#-------------------------------------------------------------------------------
my Library::App::TypeDataStore $instance;

has Version $.version;
has List $.cmd-options;
has Array $.arguments;
has Str $.project;
has Str $.library-id;

#-------------------------------------------------------------------------------
submethod BUILD (  ) { }

#-------------------------------------------------------------------------------
method instance ( --> Library::App::TypeDataStore ) {
  $instance //= self.bless;
  $instance
}

#-------------------------------------------------------------------------------
method set-version($!version) {}
method set-cmd-options($!cmd-options) {}
method set-arguments($!arguments) {}
method set-project($!project) {}
method set-library-id($!library-id) {}
