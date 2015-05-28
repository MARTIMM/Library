use v6;


use JSON::Tiny;
use Pod::To::Text;
use File::HomeDir;

=begin pod

=head1 Library::Configuration

=for head2
Class defining the location where program info can be stored.

=end pod

#-------------------------------------------------------------------------------
#
package Library {

  #-----------------------------------------------------------------------------
  #
  class Configuration {
    has Str $.filename is rw = 'Config.json';
    has Hash $!config = %( );

    my Str $t;
    my Bool $t-is-file = False;

    #---------------------------------------------------------------------------
    # We only have to load it once, after that saving is the only step needed
    #
    method load ( Bool :$use-home-dir = True ) {
      return if $t-is-file;
      $t = slurp( self.get-config-path(:$use-home-dir), :!bin);
      $t-is-file = True;
      $!config = from-json($t);
    }

    #---------------------------------------------------------------------------
    #
    method save ( Bool :$use-home-dir = True ) {
      $t = to-json($!config);
      spurt( self.get-config-path(:$use-home-dir), $t);
      $t-is-file = True;
    }

    #---------------------------------------------------------------------------
    # Set key value pairs in the config
    #
    method set ( Hash $p, Bool :$redefine = False ) {
      for $p.keys -> $k
      {
        if $!config{$k}:!exists or $!config{$k}:exists and $redefine
        {
          $!config{$k} = $p{$k};
        }
      }
    }

    #---------------------------------------------------------------------------
    #
    method get ( Str $k --> Any ) {
      return $!config{$k};
    }

    #---------------------------------------------------------------------------
    #
    method remove-config ( Bool :$use-home-dir = True ) {
      my Str $path = self.get-config-path(:$use-home-dir);
      my $dirname = $path.IO.dirname;
      unlink $path;

      if $use-home-dir {
        my $sts = rmdir($dirname);
        note "Directory $dirname not empty" if $sts != True;
      }
    }

    #---------------------------------------------------------------------------
    #
    submethod get-config-path ( Bool :$use-home-dir = True --> Str ) {
      my $path;

      # Check if file must be found in home directory as a hidden
      # <homedir>/.progname/configfile.json. If not set than use unhidden name
      # in current directory.
      #
      if $use-home-dir or $!config<use-home-dir> {
        my $home-dir = File::HomeDir.my_home;
        my $pname = "$home-dir/." ~ $*PROGRAM.IO.basename();
        $pname ~~ s/\.          # Start with the dot
                    <-[.]>+     # Then no dot may appear after that
                    $           # til the end
                   //;          # Remove found extention

        mkdir( $pname, 0o755) unless $pname.IO ~~ :d;
        $path = "$pname/$!filename";
      }

      else {
        $path = $!filename;
      }

      return $path;
    }
  }
}

