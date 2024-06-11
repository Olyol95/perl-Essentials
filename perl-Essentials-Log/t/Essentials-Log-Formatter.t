#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Overload::FileCheck '-from-stat' => \&_mock_stat, qw{:check :stat};
use Test::MockModule;
use Test::More;

use Essentials::Log::Level qw(:constants);

my $mock_time = Test::MockModule->new('Time::HiRes');
$mock_time->mock(gettimeofday => sub {
    return (1700597772, 173803);
});

use_ok('Essentials::Log::Formatter');

my $pid  = $$;
my $time = '2023-11-21 20:16:12.173803';
my $prog = 'Essentials-Log-Formatter.t';

subtest format => sub {
    subtest args => sub {
        my $level   = 'info';
        my $message = 'Test message';
        my @tests = (
            {
                args => {
                    include_level => 1,
                    include_pid   => 0,
                    include_prog  => 0,
                    include_time  => 0,
                },
                expect => "[$level] msg=\"$message\"",
                name   => 'include_level works',
            },
            {
                args => {
                    include_level => 0,
                    include_pid   => 1,
                    include_prog  => 0,
                    include_time  => 0,
                },
                expect => "<$pid> msg=\"$message\"",
                name   => 'include_pid works',
            },
            {
                args => {
                    include_level => 0,
                    include_pid   => 0,
                    include_prog  => 1,
                    include_time  => 0,
                },
                expect => "$prog: msg=\"$message\"",
                name   => 'include_prog works',
            },
            {
                args => {
                    include_level => 0,
                    include_pid   => 0,
                    include_prog  => 0,
                    include_time  => 1,
                },
                expect => "[$time UTC] msg=\"$message\"",
                name   => 'include_time works',
            },
            {
                args => {
                    include_level => 1,
                    include_pid   => 0,
                    include_prog  => 0,
                    include_time  => 1,
                },
                expect => "[$time UTC] [$level] msg=\"$message\"",
                name   => 'include_level + include_time works',
            },
            {
                args => {
                    include_level => 0,
                    include_pid   => 1,
                    include_prog  => 1,
                    include_time  => 0,
                },
                expect => "<$pid> $prog: msg=\"$message\"",
                name   => 'include_pid + include_prog works',
            },
            {
                args => {
                    include_level => 1,
                    include_pid   => 0,
                    include_prog  => 1,
                    include_time  => 0,
                },
                expect => "$prog: [$level] msg=\"$message\"",
                name   => 'include_level + include_prog works',
            },
            {
                args => {
                    include_level => 1,
                    include_pid   => 1,
                    include_prog  => 1,
                    include_time  => 1,
                },
                expect => "[$time UTC] <$pid> $prog: [$level] msg=\"$message\"",
                name   => 'all args work',
            },
            {
                args   => {},
                expect => "[$time UTC] <$pid> $prog: [$level] msg=\"$message\"",
                name   => 'everything on by default',
            }
        );
        foreach my $test (@tests) {
            my $formatter = Essentials::Log::Formatter->new(%{ $test->{args} });
            is(
                $formatter->format($INFO, $message),
                $test->{expect},
                $test->{name}
            );
        }
    };

    subtest defaults => sub {
        my @tests = (
            {
                arg    => 'include_level',
                expect => 1,
            },
            {
                arg    => 'include_pid',
                expect => 1,
            },
            {
                arg    => 'include_prog',
                expect => 1,
            },
            {
                arg    => 'include_time',
                expect => 1,
            }
        );
        my $formatter = Essentials::Log::Formatter->new;
        foreach my $test (@tests) {
            my $method = $test->{arg};
            is(
                $formatter->$method,
                $test->{expect},
                "$test->{arg} defaults to $test->{expect}"
            );
        }
    };

    subtest escape => sub {
        my $formatter = Essentials::Log::Formatter->new;
        is(
            $formatter->format($WARN, "This message\nhas new\n\nlines\n"),
            "[$time UTC] <$pid> $prog: [warn] msg=\"This message\\nhas new\\n\\nlines\"",
            'new lines are escaped'
        );
        is(
            $formatter->format($WARN, 'This message \n \contains \\\\slashes'),
            "[$time UTC] <$pid> $prog: [warn] msg=\"This message \\n \\contains \\\\slashes\"",
            'slashes are escaped'
        );
    };

    subtest multiple_values => sub {
        my $formatter = Essentials::Log::Formatter->new;
        is(
            $formatter->format(
                $ERROR,
                'This is an error!',
                {
                    stack_trace => "stack\ntrace\n123",
                    message     => 'Test message',
                    abc         => 123,
                }
            ),
            "[$time UTC] <$pid> $prog: [error] msg=\"This is an error!\" abc=\"123\" message=\"Test message\" stack_trace=\"stack\\ntrace\\n123\"",
            'multiple values formatted correctly'
        );
    };
};

subtest _is_systemd => sub {
    local $ENV{JOURNAL_STREAM} = '64769:69887159';

    subtest method => sub {
        my $formatter = Essentials::Log::Formatter->new;
        is($formatter->_is_systemd, 1, 'systemd detected correctly');
    };

    subtest defaults => sub {
        my @tests = (
            {
                arg    => 'include_level',
                expect => 1,
            },
            {
                arg    => 'include_pid',
                expect => 0,
            },
            {
                arg    => 'include_prog',
                expect => 0,
            },
            {
                arg    => 'include_time',
                expect => 0,
            }
        );
        my $formatter = Essentials::Log::Formatter->new;
        foreach my $test (@tests) {
            my $method = $test->{arg};
            is(
                $formatter->$method,
                $test->{expect},
                "$test->{arg} defaults to $test->{expect} under systemd"
            );
        }
    };
};

done_testing();

sub _mock_stat {
    my ( $stat_or_lstat, $f ) = @_;
 
    if ( defined $f && $f eq '/dev/stderr' ) {
        return [
            64769,      69887159,   33188, 1, 0, 0, 0, 13,
            1539928982, 1539716940, 1539716940,
            4096,       8
        ];
    }
 
    return FALLBACK_TO_REAL_OP;
}
