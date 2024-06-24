#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::MockModule;
use Test::MockObject;
use Test::More;

use Essentials::DB::Connection::Config;

use_ok('Essentials::DB::Pool');

subtest connect => sub {
    my $mock = Test::MockModule->new('DBIx::Class::Schema');
    $mock->mock('connect', sub {
        my ($package, @args) = @_;
        ok($package, 'Essentials::DB::Test');
        return _mock_schema(@args);
    });

    my $pool = Essentials::DB::Pool->new(
        package => 'Essentials::DB::Test',
        config  => {
            readonly  => Essentials::DB::Connection::Config->new(
                username    => 'example_ro',
                password    => 'changeme',
                driver      => 'mysql',
                driver_args => {
                    database => 'testdb',
                    hostname => 'localhost',
                },
            ),
            readwrite => Essentials::DB::Connection::Config->new(
                username    => 'example_rw',
                password    => 'hunter2',
                driver      => 'mysql',
                driver_args => {
                    database => 'testdb',
                    hostname => 'localhost',
                },
            ),
        },
    );

    my $ro = $pool->connect('readonly', { AutoCommit => 1 });
    is_deeply($ro->{args}, [
        'dbi:mysql:database=testdb;hostname=localhost',
        'example_ro',
        'changeme',
        { AutoCommit => 1 },
    ], 'readonly connect call made with correct args');

    my $rw = $pool->connect('readwrite');
    is_deeply($rw->{args}, [
        'dbi:mysql:database=testdb;hostname=localhost',
        'example_rw',
        'hunter2',
        undef,
    ], 'readonly connect call made with correct args');

    my $cached = $pool->connect('readonly');
    is($cached, $ro, 'readonly handle cached');

    $ro->disconnect;

    my $fresh = $pool->connect('readonly');
    isnt($fresh, $ro, 'readonly handle recreated after disconnect');

    my $thread_id = $$;

    ## no critic
    $$ = 1234;
    ## use critic

    isnt($pool->connect('readonly'), $fresh, 'readonly handle recreated after fork');

    ## no critic
    $$ = $thread_id;
    ## use critic

    is($pool->connect('readonly'), $fresh, 'readonly handle cached in original thread');
};

sub _mock_schema {
    my @args = @_;

    my $mock = Test::MockObject->new({
        args    => \@args,
        storage => _mock_storage(),
    });
    $mock->mock('storage', sub {
        return shift->{storage};
    });
    $mock->mock('disconnect', sub {
        shift->{storage}->{connected} = 0;
    });

    return $mock;
}

sub _mock_storage {
    my $mock = Test::MockObject->new({
        connected => 1,
    });
    $mock->mock('connected', sub {
        return shift->{connected};
    });
    return $mock;
}

done_testing();
