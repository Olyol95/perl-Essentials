#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::More;
use Test::MockModule;

my $ret_val = 1;
my $mock = _init_mock();

use_ok('Essentials::Script::Heartbeat::Systemd');

my $heartbeat = Essentials::Script::Heartbeat::Systemd->new;

subtest notify => sub {
    is($heartbeat->notify, 1, 'notify returns successfully');
    $ret_val = 0;
    is($heartbeat->notify, '', 'notify returns false if the socket is not set');
    $ret_val = -1;
    is($heartbeat->notify, '', 'notify returns false if an error occurred');
};

done_testing();

sub _init_mock {
    my $mock = Test::MockModule->new('Systemd::Daemon');
    $mock->mock('notify', sub {
        is({@_}->{WATCHDOG}, 1, 'watchdog parameter set');
        return $ret_val;
    });
    return $mock;
}
