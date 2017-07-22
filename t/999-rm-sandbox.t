use v6;
use lib 't';#, '../mongo-perl6-driver/lib';

use Test;
use Test-support;

#------------------------------------------------------------------------------
my Library::Test-support $ts .= new;

#------------------------------------------------------------------------------
for $ts.server-range -> $server-number {

  try {
    ok $ts.server-control.stop-mongod('s' ~ $server-number),
       "Server $server-number is stopped";
    CATCH {
      when X::MongoDB {
        like .message, /:s exited unsuccessfully/,
             "Server 's$server-number' already down";
      }
    }
  }
}

$ts.cleanup-sandbox();

#------------------------------------------------------------------------------
# Cleanup and close
done-testing();
exit(0);
