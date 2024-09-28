#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::More;
use Try::Tiny;

use Essentials::Beanstalk::Priority qw($HIGH $MEDIUM);

use_ok('Essentials::Beanstalk::Client');

subtest extends_beanstalk_client => sub {
    my $client = Essentials::Beanstalk::Client->new;
    ok($client->$_isa('Beanstalk::Client'), 'Inherits from Beanstalk::Client');
};

subtest default_priority => sub {
    my $client = Essentials::Beanstalk::Client->new;
    is($client->priority, $MEDIUM, 'default priority is $MEDIUM');
};

subtest priority_override => sub {
    my $client = Essentials::Beanstalk::Client->new(priority => $HIGH);
    is($client->priority, $HIGH, 'priority overridden to $HIGH');
};

subtest error_none => sub {
    my $client = Essentials::Beanstalk::Client->new;
    is($client->error, undef, 'returns undef when no error is set');
};

subtest error_timeout => sub {
    my $client = Essentials::Beanstalk::Client->new;
    $client->{error} = 'TIMED_OUT';
    is($client->error, 'TIMED_OUT', 'TIMED_OUT error is returned non-fatally');
};

subtest error_interrupted => sub {
    my $client = Essentials::Beanstalk::Client->new;
    $client->{error} = 'Interrupted system call';
    is($client->error, 'Interrupted system call', 'Interrupted system call error is returned non-fatally');
};

subtest error_fatal => sub {
    my $client = Essentials::Beanstalk::Client->new;
    $client->{error} = 'OUT_OF_MEMORY';

    my $exception;
    try {
        $client->error;
    }
    catch {
        $exception = $_;
    };

    ok($exception->$_isa('Essentials::Exception'), 'fatal error throws an Essentials::Exception');
    like($exception->message, qr/OUT_OF_MEMORY/, 'exception message contains the error');
};

done_testing();
