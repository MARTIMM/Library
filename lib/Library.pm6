use v6;
use Library::Configuration;

say 'Library file ping...';
package Library
{
say 'Library package ping...';
  our $cfg = Library::Configuration.new();
  $cfg.set( { MongoDB_Server => 'localhost'
            , port => '2222'
            , database => 'Library'
            , collections =>
              { meta => metadata
              }
            }
          );
  $cfg.save();
}
