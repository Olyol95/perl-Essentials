#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::MockModule;
use Test::More;

use Essentials::DB::Connection::Config;

use_ok('Essentials::DB');

subtest package => sub {
    my $db = Essentials::DB->new(package => 'Essentials::DB::Test');

    is($db->package, 'Essentials::DB::Test', 'package name correct');
    ok($db->package->does('Essentials::DB::Connection'), 'Composes the Essentials::DB::Connection role');
    isa_ok($db->package, 'DBIx::Class::Schema');
    can_ok($db->package, 'connect');
};

subtest connect => sub {
    my $mock = Test::MockModule->new('DBIx::Class::Schema');
    $mock->mock('connect', sub {
        my ($package, @args) = @_;
        ok($package, 'Essentials::DB::Test');
        return \@args;
    });

    my $db = Essentials::DB->new(package => 'Essentials::DB::Test');
    my $args = $db->connect(
        Essentials::DB::Connection::Config->new(
            username    => 'example',
            password    => 'changeme',
            driver      => 'mysql',
            driver_args => {
                database => 'testdb',
                hostname => 'localhost',
            },
        ),
        { AutoCommit => 1 },
    );

    is_deeply($args, [
        'dbi:mysql:database=testdb;hostname=localhost',
        'example',
        'changeme',
        { AutoCommit => 1 },
    ], 'underlying connect call made with correct args');
};

done_testing();
