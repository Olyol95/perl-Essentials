#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::MockObject;
use Test::More;

use Essentials::Exception;
use Essentials::Log::Level qw(:constants);

use_ok('Essentials::Log');

subtest defaults => sub {
    my $log = Essentials::Log->new;
    ok(
        $log->formatter->$_isa('Essentials::Log::Formatter'),
        'formatter populated by default'
    );
    is($log->level, $INFO, 'default log level is $INFO');
    ok(
        $log->writer->$_isa('Essentials::Log::Writer'),
        'writer populated by default'
    );
};

subtest level => sub {
    my $message = 'Test message';
    my $data    = {
        abc     => 123,
        example => 'message',
    };
    my @tests = (
        {
            level  => $INFO,
            sub    => 'trace',
            expect => [],
            name   => 'trace not logged at info level',
        },
        {
            level  => $INFO,
            sub    => 'debug',
            expect => [],
            name   => 'debug not logged at info level',
        },
        {
            level  => $INFO,
            sub    => 'info',
            expect => [{
                level   => $INFO,
                message => $message,
                data    => $data,
            }],
            name   => 'info logged at info level',
        },
        {
            level  => $INFO,
            sub    => 'warn',
            expect => [{
                level   => $WARN,
                message => $message,
                data    => $data,
            }],
            name   => 'warn logged at info level',
        },
        {
            level  => $INFO,
            sub    => 'error',
            expect => [{
                level   => $ERROR,
                message => $message,
                data    => $data,
            }],
            name   => 'error logged at info level',
        },
        {
            level  => $ERROR,
            sub    => 'trace',
            expect => [],
            name   => 'trace not logged at error level',
        },
        {
            level  => $ERROR,
            sub    => 'debug',
            expect => [],
            name   => 'debug not logged at error level',
        },
        {
            level  => $ERROR,
            sub    => 'info',
            expect => [],
            name   => 'info not logged at error level',
        },
        {
            level  => $ERROR,
            sub    => 'warn',
            expect => [],
            name   => 'warn not logged at error level',
        },
        {
            level  => $ERROR,
            sub    => 'error',
            expect => [{
                level   => $ERROR,
                message => $message,
                data    => $data,
            }],
            name   => 'error logged at error level',
        },
        {
            level  => $TRACE,
            sub    => 'trace',
            expect => [{
                level   => $TRACE,
                message => $message,
                data    => $data,
            }],
            name   => 'trace logged at trace level',
        },
        {
            level  => $TRACE,
            sub    => 'debug',
            expect => [{
                level   => $DEBUG,
                message => $message,
                data    => $data,
            }],
            name   => 'debug logged at trace level',
        },
        {
            level  => $TRACE,
            sub    => 'info',
            expect => [{
                level   => $INFO,
                message => $message,
                data    => $data,
            }],
            name   => 'info logged at trace level',
        },
        {
            level  => $TRACE,
            sub    => 'warn',
            expect => [{
                level   => $WARN,
                message => $message,
                data    => $data,
            }],
            name   => 'warn logged at trace level',
        },
        {
            level  => $TRACE,
            sub    => 'error',
            expect => [{
                level   => $ERROR,
                message => $message,
                data    => $data,
            }],
            name   => 'error logged at trace level',
        },
    );
    foreach my $test (@tests) {
        my $writer = mock_writer();
        my $log = Essentials::Log->new(
            formatter => mock_formatter(),
            writer    => $writer,
            level     => $test->{level},
        );
        my $sub = $test->{sub};
        $log->$sub($message, $data);
        is_deeply(
            $writer->calls,
            $test->{expect},
            $test->{name}
        );
    }
};

subtest data => sub {
    subtest no_data => sub {
        my $writer = mock_writer();
        my $log = Essentials::Log->new(
            formatter => mock_formatter(),
            writer    => $writer,
            level     => $INFO,
        );
        $log->info('Message');
        is_deeply(
            $writer->calls,
            [{
                level   => $INFO,
                message => 'Message',
                data    => {},
            }],
            'Data is not required'
        );
    };

    subtest example_data => sub {
        my $writer = mock_writer();
        my $log = Essentials::Log->new(
            formatter => mock_formatter(),
            writer    => $writer,
            level     => $INFO,
        );
        $log->info('Message', { key => 'value' });
        is_deeply(
            $writer->calls,
            [{
                level   => $INFO,
                message => 'Message',
                data    => {
                    key => 'value',
                },
            }],
            'Data is passed through'
        );
    };
};

subtest context => sub {
    my @tests = (
        {
            data    => undef,
            context => {
                abc     => 123,
                example => 'value',
            },
            expect  => [{
                level   => $INFO,
                message => 'Message',
                data    => {
                    abc     => 123,
                    example => 'value',
                },
            }],
            name => 'context with no data works',
        },
        {
            data    => {
                exists => 'test',
            },
            context => {
                abc     => 123,
                example => 'value',
            },
            expect  => [{
                level   => $INFO,
                message => 'Message',
                data    => {
                    abc     => 123,
                    example => 'value',
                    exists  => 'test',
                },
            }],
            name => 'context with data works',
        },
        {
            data    => {
                exists => 'override',
            },
            context => {
                abc     => 123,
                exists => 'test',
            },
            expect  => [{
                level   => $INFO,
                message => 'Message',
                data    => {
                    abc     => 123,
                    exists  => 'override',
                },
            }],
            name => 'context with override works',
        },
    );
    foreach my $test (@tests) {
        my $writer = mock_writer();
        my $log = Essentials::Log->new(
            formatter => mock_formatter(),
            writer    => $writer,
            level     => $INFO,
        );
        while (my ($key, $value) = each %{ $test->{context} }) {
            $log->context->{$key} = $value;
        }
        $log->info('Message', $test->{data});
        is_deeply(
            $writer->calls,
            $test->{expect},
            $test->{name}
        );
    }
};

subtest exception => sub {
    my $exception = Essentials::Exception->new(
        message     => 'Example Exception',
        stack_trace => 'Example stack trace',
    );
    my @tests = (
        {
            level  => $TRACE,
            expect => [{
                level   => $ERROR,
                message => 'Example Exception',
                data    => {
                    stack_trace => 'Example stack trace',
                },
            }],
            name   => 'Stack trace included at trace',
        },
        {
            level  => $DEBUG,
            expect => [{
                level   => $ERROR,
                message => 'Example Exception',
                data    => {
                    stack_trace => 'Example stack trace',
                },
            }],
            name   => 'Stack trace included at debug',
        },
        {
            level  => $INFO,
            expect => [{
                level   => $ERROR,
                message => 'Example Exception',
                data    => {},
            }],
            name   => 'Stack trace not included at info',
        },
        {
            level  => $WARN,
            expect => [{
                level   => $ERROR,
                message => 'Example Exception',
                data    => {},
            }],
            name   => 'Stack trace not included at warn',
        },
        {
            level  => $ERROR,
            expect => [{
                level   => $ERROR,
                message => 'Example Exception',
                data    => {},
            }],
            name   => 'Stack trace not included at error',
        },
    );
    foreach my $test (@tests) {
        my $writer = mock_writer();
        my $log = Essentials::Log->new(
            formatter => mock_formatter(),
            writer    => $writer,
            level     => $test->{level},
        );
        $log->error($exception);
        is_deeply(
            $writer->calls,
            $test->{expect},
            $test->{name}
        );
    }
};

done_testing();

sub mock_formatter {
    my $formatter = Test::MockObject->new;
    $formatter->mock(format => sub {
        my ($self, $level, $message, $data) = @_;
        return {
            level   => $level,
            message => $message,
            data    => $data,
        };
    });
    return $formatter;
}

sub mock_writer {
    my $writer = Test::MockObject->new({
        calls => [],
    });
    $writer->mock(write => sub {
        my ($self, $message) = @_;
        push @{ $self->{calls} }, $message;
    });
    $writer->mock(calls => sub {
        my $self = shift;
        return $self->{calls};
    });
    return $writer;
}
