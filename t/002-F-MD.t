use v6;
use Test;

use Library::Configuration;
use Library::File-metadata-manager;

my Library::Configuration $cfg = Library::Configuration.new();
is $cfg.isa(Library::Configuration), True, 'Is a Library::Configuration';


my Library::File-metadata-manager $meta = Library::File-metadata-manager.new();

is $meta.isa(Library::File-metadata-manager), True, 'Type is File-metadata-manager';

done;

exit(0);

