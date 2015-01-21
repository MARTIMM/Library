use v6;

use MongoDB;
use Library;
use Library::Configuration;

#------------------------------------------------------------------------------
#
package Library
{
  role MetaDB
  {
    our $connection = MongoDB::Connection.new( :host('localhost')
                                             , :port(27017)
                                             );

    method meta-insert(%document)
    {
      $connection.insert(%document);
    }
  }

  #----------------------------------------------------------------------------
  #
  class File-metadata-manager does MetaDB
  {
    my Str @source-locations;
    
    method process-file ( Str $document-path )
    {
      say "Server: ", $Library::cfg.get('MongoDB_Server');
      my $path = $document-path.IO.dir;
      my $name = $document-path.IO.basename;
      $name ~~ /\.(<-[^.]>+)$/;
      my $type = $/[0];
      say "Type of $name is $type";
      
      # search it first
      
      # set
      #
      self.meta-insert\
      ( %( name => $document-path
         , type => $type
         )
      );
    }
  }
}


