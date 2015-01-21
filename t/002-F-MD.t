use v6;
use Test;

use Library::Configuration;
use Library::File-metadata-manager;

my Library::File-metadata-manager $meta .= new();

ok $meta.WHICH ~~ /File\-metadata\-manager\|\d+/, 'Check type';

done;

exit(0);

