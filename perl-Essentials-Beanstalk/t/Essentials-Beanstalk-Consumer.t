#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::MockModule;
use Test::MockObject;
use Test::More;

use_ok('Essentials::Beanstalk::Consumer');

{
    package Essentials::Beanstalk::Consumer::Test;

    use Moo;

    with 'Essentials::Beanstalk::Consumer';

    sub default_tube {
        return 'test-tube';
    }

    sub process_job {}

    1;
}

{
    package Essentials::Beanstalk::Test::Job;

    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }

    ## no critic
    sub id       { return $_[0]->{id} }
    sub delete   { return 1 }
    sub release  { return 1 }
    sub bury     { return 1 }

    sub stats {
        my $self = shift;
        return bless { reserves => $self->{reserves} }, 'Essentials::Beanstalk::Test::Job::Stats';
    }

    package Essentials::Beanstalk::Test::Job::Stats;

    sub reserves { return $_[0]->{reserves} }
    ## use critic
}

my $mock = Test::MockModule->new('Essentials::Beanstalk::Client');
$mock->mock('connect',    sub {});
$mock->mock('use',        sub {});
$mock->mock('watch_only', sub {});

subtest composes_script_service => sub {
    my $consumer = Essentials::Beanstalk::Consumer::Test->new;
    ok($consumer->$_does('Essentials::Script::Service'), 'composes Essentials::Script::Service');
};

subtest defaults => sub {
    my $consumer = Essentials::Beanstalk::Consumer::Test->new;
    is($consumer->reserve_timeout, 3, 'reserve_timeout defaults to 3');
    is($consumer->retries, 2, 'retries defaults to 2');
    is($consumer->tube, 'test-tube', 'tube uses default_tube');
};

subtest tube_override => sub {
    my $consumer = Essentials::Beanstalk::Consumer::Test->new(tube => 'custom-tube');
    is($consumer->tube, 'custom-tube', 'tube attribute can be overridden');
};

subtest run_processes_job => sub {
    my $processed_job;

    $mock->mock('reserve', sub { Essentials::Beanstalk::Test::Job->new(id => 42, reserves => 1) });
    $mock->mock('error',   sub { undef });

    {
        no warnings 'redefine';
        local *Essentials::Beanstalk::Consumer::Test::process_job = sub {
            my ($self, $job) = @_;
            $processed_job = $job;
        };
        my $consumer = Essentials::Beanstalk::Consumer::Test->new;
        $consumer->run;
    }

    ok(defined $processed_job,              'process_job was called');
    is($processed_job->id, 42,             'process_job received the correct job');
};

subtest run_handles_timeout => sub {
    $mock->mock('reserve', sub { return undef });
    $mock->mock('error',   sub { 'TIMED_OUT' });

    my $consumer = Essentials::Beanstalk::Consumer::Test->new;

    my $ok = eval { $consumer->run; 1 };
    ok($ok, 'run completes without error on timeout');
};

subtest run_releases_job_on_failure => sub {
    my $released;

    $mock->mock('reserve', sub { Essentials::Beanstalk::Test::Job->new(id => 1, reserves => 1) });
    $mock->mock('error',   sub { undef });

    {
        no warnings 'redefine';
        local *Essentials::Beanstalk::Consumer::Test::process_job = sub {
            die "processing failed\n";
        };
        ## no critic
        local *Essentials::Beanstalk::Test::Job::release = sub { $released = 1 };
        ## use critic
        my $consumer = Essentials::Beanstalk::Consumer::Test->new;
        $consumer->run;
    }

    ok($released, 'job is released when retries not exceeded');
};

subtest run_buries_job_when_retries_exceeded => sub {
    my $buried;

    # reserves > retries (default retries = 2, so reserves = 3 triggers bury)
    $mock->mock('reserve', sub { Essentials::Beanstalk::Test::Job->new(id => 1, reserves => 3) });
    $mock->mock('error',   sub { undef });

    {
        no warnings 'redefine';
        local *Essentials::Beanstalk::Consumer::Test::process_job = sub {
            die "processing failed\n";
        };
        ## no critic
        local *Essentials::Beanstalk::Test::Job::bury = sub { $buried = 1 };
        ## use critic
        my $consumer = Essentials::Beanstalk::Consumer::Test->new;
        $consumer->run;
    }

    ok($buried, 'job is buried when retries exceeded');
};

done_testing();
