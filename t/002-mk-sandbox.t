use v6;
use lib 't';

use Test;
use Test-support;

use MongoDB::Server::Control;

#-------------------------------------------------------------------------------
my Library::Test-support $ts .= new;

#-------------------------------------------------------------------------------
for $ts.server-range -> $server-number {
  try {
    ok $ts.server-control.start-mongod("s$server-number"),
       "Server $server-number started";
    CATCH {
      when X::MongoDB {
        like .message, /:s exited unsuccessfully /,
             "Server 's$server-number' already started";
      }
    }
  }
}

#-------------------------------------------------------------------------------
# Cleanup and close
done-testing();
exit(0);
