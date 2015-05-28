use v6;


use Library::Configuration;
use MongoDB::Connection;

#say 'Library file ping...';

package Library:ver<0.2.1> {

#say 'Library package ping...';
  our $cfg = Library::Configuration.new();
  $cfg.set( { MongoDB_Server => 'localhost',
              port => '27017',
              database => 'Library',
              collections => {
                documents => 'docs_metadata',
                mimetypes => 'mimetypes'
              }
            }
          );
  $cfg.save();

  our $connection = MongoDB::Connection.new(
        :host($cfg.get('MongoDB_Server')),
        :port(Int($cfg.get('port')))
      );
}
