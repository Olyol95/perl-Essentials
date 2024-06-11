#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::Exception;
use Test::More;

use_ok('Essentials::Log::Level');

use Essentials::Log::Level qw(:constants from_string);

subtest constants => sub {
    my @tests = (
        {
            constant => $TRACE,
            value    => 1,
            string   => 'trace',
        },
        {
            constant => $DEBUG,
            value    => 2,
            string   => 'debug',
        },
        {
            constant => $INFO,
            value    => 3,
            string   => 'info',
        },
        {
            constant => $WARN,
            value    => 4,
            string   => 'warn',
        },
        {
            constant => $ERROR,
            value    => 5,
            string   => 'error',
        },
    );
    foreach my $test (@tests) {
        is(
            int $test->{constant},
            $test->{value},
            "$test->{constant} int value ok"
        );
        is(
            "$test->{constant}",
            $test->{string},
            "$test->{constant} string value ok"
        );
    }
};

subtest from_string => sub {
    my @ok_tests = (
        {
            string   => 'info',
            expected => $INFO,
        },
        {
            string   => 'INFO',
            expected => $INFO,
        },
        {
            string   => 'wArN',
            expected => $WARN,
        },
    );
    foreach my $test (@ok_tests) {
        is(
            from_string($test->{string}),
            $test->{expected},
            "$test->{string} returns the correct level"
        );
    }
    my @error_tests = (
        {
            string   => 3,
            expected => qr/Unknown log level/,
            name     => 'number throws an error',
        },
        {
            string   => 'nonsense',
            expected => qr/Unknown log level/,
            name     => 'invalid string throws an error',
        },
        {
            string   => undef,
            expected => qr/No string provided/,
            name     => 'undef throws an error',
        },
        {
            string   => '',
            expected => qr/No string provided/,
            name     => 'empty string throws an error',
        },
        {
            string   => 0,
            expected => qr/No string provided/,
            name     => 'zero throws an error',
        },
    );
    foreach my $test (@error_tests) {
        throws_ok {
            from_string($test->{string});
        } $test->{expected}, $test->{name};
    }
};

done_testing();
