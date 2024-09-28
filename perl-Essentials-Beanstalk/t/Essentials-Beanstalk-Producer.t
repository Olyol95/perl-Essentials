#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::MockModule;
use Test::More;
use Try::Tiny;

use_ok('Essentials::Beanstalk::Producer');

{
    package Essentials::Beanstalk::Producer::Test;

    use Moo;

    with 'Essentials::Beanstalk::Producer';

    1;
}

my $mock = Test::MockModule->new('Essentials::Beanstalk::Client');
$mock->mock('connect', sub {});

subtest composes_producer => sub {
    my $producer = Essentials::Beanstalk::Producer::Test->new;
    ok($producer->$_does('Essentials::Beanstalk::Producer'), 'composes Essentials::Beanstalk::Producer');
};

subtest no_tube => sub {
    my $producer = Essentials::Beanstalk::Producer::Test->new;

    my $exception;
    try {
        $producer->add_job(undef, { foo => 'bar' });
    }
    catch {
        $exception = $_;
    };

    ok($exception->$_isa('Essentials::Exception'), 'throws Essentials::Exception when no tube provided');
    like($exception->message, qr/No tube provided/, 'exception message is correct');
};

subtest no_data => sub {
    my $producer = Essentials::Beanstalk::Producer::Test->new;

    my $exception;
    try {
        $producer->add_job('my-tube', undef);
    }
    catch {
        $exception = $_;
    };

    ok($exception->$_isa('Essentials::Exception'), 'throws Essentials::Exception when no data provided');
    like($exception->message, qr/No job data provided/, 'exception message is correct');
};

subtest non_hashref_data => sub {
    my $producer = Essentials::Beanstalk::Producer::Test->new;

    my $exception;
    try {
        $producer->add_job('my-tube', 'not-a-hashref');
    }
    catch {
        $exception = $_;
    };

    ok($exception->$_isa('Essentials::Exception'), 'throws Essentials::Exception when data is not a hashref');
    like($exception->message, qr/Job data must be a hashref/, 'exception message is correct');
};

subtest add_job_success => sub {
    my @use_calls;
    my @put_calls;
    my $mock_job = bless {}, 'Beanstalk::Job';

    $mock->mock('use', sub { push @use_calls, $_[1] });
    $mock->mock('put', sub {
        push @put_calls, { args => $_[1], data => $_[2] };
        return $mock_job;
    });

    my $producer = Essentials::Beanstalk::Producer::Test->new;
    my $job = $producer->add_job('my-tube', { example => 'data' });

    is(scalar @use_calls, 1,          'client->use called once');
    is($use_calls[0],     'my-tube',  'client->use called with correct tube');
    is(scalar @put_calls, 1,          'client->put called once');
    is_deeply($put_calls[0]->{data},  { example => 'data' }, 'job data passed correctly');
    is($put_calls[0]->{args}->{delay}, 0,  'default delay is 0');
    is($put_calls[0]->{args}->{ttr},   60, 'default ttr is 60');
    is($job, $mock_job, 'returns the job from client->put');
};

subtest add_job_with_args => sub {
    my @put_calls;
    my $mock_job = bless {}, 'Beanstalk::Job';

    $mock->mock('use', sub {});
    $mock->mock('put', sub {
        push @put_calls, { args => $_[1], data => $_[2] };
        return $mock_job;
    });

    my $producer = Essentials::Beanstalk::Producer::Test->new;
    $producer->add_job('my-tube', { example => 'data' }, { delay => 30, ttr => 120 });

    is($put_calls[0]->{args}->{delay}, 30,  'custom delay is passed through');
    is($put_calls[0]->{args}->{ttr},   120, 'custom ttr is passed through');
};

subtest add_job_put_failure => sub {
    $mock->mock('use', sub {});
    $mock->mock('put', sub { return undef });
    $mock->mock('error', sub { 'INTERNAL_ERROR' });

    my $producer = Essentials::Beanstalk::Producer::Test->new;

    my $exception;
    try {
        $producer->add_job('my-tube', { example => 'data' });
    }
    catch {
        $exception = $_;
    };

    ok($exception->$_isa('Essentials::Exception'), 'throws Essentials::Exception when put returns falsy');
    like($exception->message, qr/Error queueing job/, 'exception message is correct');
};

done_testing();
