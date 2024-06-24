#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::More;

use_ok('Essentials::Script::Heartbeat::None');

my $heartbeat = Essentials::Script::Heartbeat::None->new;

subtest notify => sub {
    is($heartbeat->notify, 1, 'notify returns successfully');
};

done_testing();
