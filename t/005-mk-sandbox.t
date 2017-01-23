use v6.c;
use lib 't';

use Test;
use Test-support;

use MongoDB;
use MongoDB::Server::Control;

#-------------------------------------------------------------------------------
#drop-send-to('mongodb');
#drop-send-to('screen');
#add-send-to( 'screen', :to($*ERR), :level(* >= MongoDB::Loglevels::Trace));
info-message("Test $?FILE start");

my Library::Test-support $ts .= new;

#-------------------------------------------------------------------------------
for $ts.server-range -> $server-number {
  ok $ts.server-control.start-mongod("s$server-number"),
     "Server $server-number started";
}

#-------------------------------------------------------------------------------
# Cleanup and close
#
info-message("Test $?FILE stop");
sleep .2;
drop-all-send-to();
done-testing();
exit(0);
