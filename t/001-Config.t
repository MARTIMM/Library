use v6;
use Test;

use File::HomeDir;

use Library::Configuration;
#use_ok Library::Configuration;

#-------------------------------------------------------------------------------
#
my Library::Configuration $cfg .= new;
my Str $filename = 'my-config.json';

# Test filename
#
is $cfg.filename, 'Config.json', 'Check filename = Config.json';
$cfg.filename = $filename;
is $cfg.filename, $filename, "Check filename = '$filename'";
is $cfg.get-config-path()
 , ([~] File::HomeDir.my_home, '/', '.001-Config/', $cfg.filename)
 , "Check config path in home dir"
 ;
is $cfg.get-config-path(:!use-home-dir)
 , $cfg.filename
 , "Check config path in current dir"
 ;

$cfg.set( {MongoDB_Server => 'localhost:2222'});
$cfg.save(:!use-home-dir);
$cfg.load(:!use-home-dir);

ok $cfg.filename.IO ~~ :r, "$filename exists";

my $server = $cfg.get('MongoDB_Server');
is $server, 'localhost:2222', qq/Key check = '$server'/;

$cfg.set( {MongoDB_Server => '192.168.0.22:2222'});
$server = $cfg.get('MongoDB_Server');
is $server, 'localhost:2222', qq/Key check still = '$server'/;

$cfg.set( {MongoDB_Server => '192.168.0.22:2222'}, :redefine);
$server = $cfg.get('MongoDB_Server');
is $server, '192.168.0.22:2222', qq/Key changed now = '$server'/;

#-------------------------------------------------------------------------------
$cfg.save();
$cfg.load();

$cfg.remove-config();
my Str $cf-name = [~] File::HomeDir.my_home, '/', '.001-Config/', $cfg.filename;
ok !($cf-name.IO ~~ :r), "$cf-name does'nt exist anymore";

$cfg.remove-config(:!use-home-dir);
ok !($cfg.filename.IO ~~ :r), "$filename doesn't exist anymore";

#-------------------------------------------------------------------------------


done;

#unlink $filename;

exit(0);

