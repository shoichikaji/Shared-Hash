use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Shared::Hash
    Shared::Hash::File
    Shared::Hash::UNIX
    Shared::Hash::UNIX::Base
    Shared::Hash::UNIX::Client
    Shared::Hash::UNIX::Server
);

done_testing;

