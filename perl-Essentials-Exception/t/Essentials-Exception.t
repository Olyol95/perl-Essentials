#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::More;
use Test::Exception;
use Try::Tiny;

use_ok('Essentials::Exception');

use Essentials::Exception qw(throw);

subtest throw => sub {
    throws_ok {
        throw "Test exception";
    } 'Essentials::Exception', 'Exception object thrown';

    try {
        throw;
    }
    catch {
        is($_->message, 'Unknown', 'Default message thrown correctly');
        like($_->stack_trace, qr/ at t\/Essentials-Exception[.]t line \d+[.]\n/, 'Stack trace included');
    };

    try {
        throw "Example message";
    }
    catch {
        is($_->message, 'Example message', 'Message thrown correctly');
        like($_->stack_trace, qr/ at t\/Essentials-Exception[.]t line \d+[.]\n/, 'Stack trace included');
    };
};

subtest to_string => sub {
    my $exception = Essentials::Exception->new(
        message     => 'Test',
        stack_trace => '',
    );
    is("$exception", 'Test', 'Stringified correctly');
};

done_testing();
