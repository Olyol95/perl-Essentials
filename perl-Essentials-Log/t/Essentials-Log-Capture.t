#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::MockObject;
use Test::More;

use_ok('Essentials::Log::Capture');

subtest print => sub {
    subtest buffering => sub {
        my $log = mock_log();
        my $fh  = tie_capture(log => $log);
        print {$fh} 'partial';
        is_deeply($log->calls, [], 'incomplete line is buffered');
        print {$fh} " line\n";
        is_deeply(
            $log->calls,
            [{ level => 'info', message => 'partial line' }],
            'buffered content is flushed once a newline arrives'
        );
    };

    subtest multiple_lines => sub {
        my $log = mock_log();
        my $fh  = tie_capture(log => $log);
        print {$fh} "one\ntwo\nthree\n";
        is_deeply(
            $log->calls,
            [
                { level => 'info', message => 'one' },
                { level => 'info', message => 'two' },
                { level => 'info', message => 'three' },
            ],
            'each line is logged separately'
        );
    };

    subtest separators => sub {
        my $log = mock_log();
        my $fh  = tie_capture(log => $log);
        local $, = ',';
        local $\ = "\n";
        print {$fh} 'a', 'b', 'c';
        is_deeply(
            $log->calls,
            [{ level => 'info', message => 'a,b,c' }],
            'field and record separators are honoured'
        );
    };

    subtest empty => sub {
        my $log = mock_log();
        my $fh  = tie_capture(log => $log);
        print {$fh} '';
        is_deeply($log->calls, [], 'empty writes are ignored');
    };
};

subtest printf => sub {
    my $log = mock_log();
    my $fh  = tie_capture(log => $log);
    printf {$fh} "%s=%d\n", 'answer', 42;
    is_deeply(
        $log->calls,
        [{ level => 'info', message => 'answer=42' }],
        'printf output is logged'
    );
};

subtest write => sub {
    subtest syswrite => sub {
        my $log = mock_log();
        my $fh  = tie_capture(log => $log);
        my $written = syswrite($fh, "line\n");
        is($written, 5, 'returns the number of bytes written');
        is_deeply(
            $log->calls,
            [{ level => 'info', message => 'line' }],
            'syswrite output is logged'
        );
    };

    subtest offset_and_length => sub {
        my $log = mock_log();
        my $fh  = tie_capture(log => $log);
        my $written = syswrite($fh, 'ABCDEF', 3, 2);
        is($written, 3, 'returns the requested length');
        tied(*$fh)->flush;
        is_deeply(
            $log->calls,
            [{ level => 'info', message => 'CDE' }],
            'offset and length are respected'
        );
    };
};

subtest flush => sub {
    my $log = mock_log();
    my $fh  = tie_capture(log => $log);
    print {$fh} 'no trailing newline';
    is_deeply($log->calls, [], 'content without a newline stays buffered');
    tied(*$fh)->flush;
    is_deeply(
        $log->calls,
        [{ level => 'info', message => 'no trailing newline' }],
        'flush logs the remaining buffer'
    );
    tied(*$fh)->flush;
    is_deeply(
        $log->calls,
        [{ level => 'info', message => 'no trailing newline' }],
        'flushing an empty buffer is a no-op'
    );
};

subtest close => sub {
    my $log = mock_log();
    my $fh  = tie_capture(log => $log);
    print {$fh} 'buffered';
    close($fh);
    is_deeply(
        $log->calls,
        [{ level => 'info', message => 'buffered' }],
        'close flushes the buffer'
    );
};

subtest stream => sub {
    my @tests = (
        {
            stream => 'stdout',
            expect => 'info',
            name   => 'stdout is routed to info',
        },
        {
            stream => 'stderr',
            expect => 'warn',
            name   => 'stderr is routed to warn',
        },
    );
    foreach my $test (@tests) {
        my $log = mock_log();
        my $fh  = tie_capture(
            stream => $test->{stream},
            log    => $log,
        );
        print {$fh} "message\n";
        is_deeply(
            $log->calls,
            [{ level => $test->{expect}, message => 'message' }],
            $test->{name}
        );
    }
};

subtest handle_protocol => sub {
    my $log = mock_log();
    my $fh  = tie_capture(log => $log);
    ok(binmode($fh), 'binmode succeeds');
    is(fileno($fh), -1, 'fileno reports -1');
};

done_testing();

sub tie_capture {
    my %args = @_;

    my $fh = \do { local *FH };
    tie *$fh, 'Essentials::Log::Capture',
        stream => $args{stream} // 'stdout',
        log    => $args{log};
    return $fh;
}

sub mock_log {
    my $log = Test::MockObject->new({
        calls => [],
    });
    $log->mock(info => sub {
        my ($self, $message) = @_;
        push @{ $self->{calls} }, { level => 'info', message => $message };
    });
    $log->mock(warn => sub {
        my ($self, $message) = @_;
        push @{ $self->{calls} }, { level => 'warn', message => $message };
    });
    $log->mock(calls => sub {
        my $self = shift;
        return $self->{calls};
    });
    return $log;
}
