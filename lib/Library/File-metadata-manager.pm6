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
    my $cfg = $Library::cfg;
    our $connection = MongoDB::Connection.new\
        ( :host($cfg.get('MongoDB_Server'))
        , :port(Int($cfg.get('port')))
        );
    our $database = $connection.database($cfg.get('database'));
    our $collection = $database.collection($cfg.get('collections')<documents>);

    method meta-insert ( %document )
    {
      $collection.insert(%document);
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
      my $type = ~$/[0];
      say "Type of $name is $type";
      
      # search it first
      
      # set
      #
      self.meta-insert( %( name => $document-path
                         , type => $type
                         )
                      );
    }
  }
}


