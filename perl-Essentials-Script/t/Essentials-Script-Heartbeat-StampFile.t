#!/usr/bin/env perl

use v5.26;
use strictures 2;

use DateTime;
use Test::MockTime qw(set_absolute_time);
use Test::MockFile;
use Test::More;

use_ok('Essentials::Script::Heartbeat::StampFile');

set_absolute_time('2025-07-19T19:30:00Z');

subtest notify => sub {
    my @tests = (
        {
            name => 'default file',
            args => {},
            extra => sub {
                my $heartbeat = shift;
                ok($heartbeat->file_name =~ /t-Essentials-Script-Heartbeat-StampFile\.t\.stamp$/, 'file name format correct');
            },
        },
        {
            name => 'custom file',
            args => {
                file_name => 'example-file.stamp',
            },
        },
    );
    foreach my $test (@tests) {
        subtest $test->{name} => sub {
            my $heartbeat = Essentials::Script::Heartbeat::StampFile->new(
                %{ $test->{args} },
            );
            my $file = Test::MockFile->file($heartbeat->file_name);
            ok(!-f $heartbeat->file_name, 'file not yet present');
            is($heartbeat->notify, 1, 'notify returns successfully');
            ok(-f $heartbeat->file_name, 'file created');
            is($heartbeat->notify, 1, 'subsequent notify returns successfully');
            is(last_updated_time($heartbeat->file_name), '2025-07-19 19:30:00', 'subsequent last update time is correct');
            $test->{extra}->($heartbeat) if exists $test->{extra};
        };
    }
};

subtest unlink_on_exit => sub {
    my $file_name = 'example.txt';
    my $file = Test::MockFile->file($file_name);

    {
        my $heartbeat = Essentials::Script::Heartbeat::StampFile->new(
            file_name      => $file_name,
            unlink_on_exit => 0,
        );
        $heartbeat->notify;
        ok(-f $file_name, 'file exists');
    }
    ok(-f $file_name, 'file still exists after destruction');

    {
        my $heartbeat = Essentials::Script::Heartbeat::StampFile->new(
            file_name      => $file_name,
            unlink_on_exit => 1,
        );
        $heartbeat->notify;
        ok(-f $file_name, 'file exists');
    }
    ok(!-f $file_name, 'file no longer exists after destruction');
};

sub last_updated_time {
    my $file_name = shift;

    open my $fh, '<', $file_name or die "Couldn't open $file_name: $!";
    my $date = DateTime->from_epoch(
        epoch => (stat($fh))[9],
    );
    close $fh;

    return $date->strftime('%F %T');
}

done_testing();
