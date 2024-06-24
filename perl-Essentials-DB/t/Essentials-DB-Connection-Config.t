#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::More;

use_ok('Essentials::DB::Connection::Config');

subtest dsn => sub {
    my @tests = (
        {
            name   => 'SQLite',
            args   => {
                driver      => 'SQLite',
                driver_args => {
                    dbname => '/path/to/database.db',
                },
            },
            expect => 'dbi:SQLite:dbname=/path/to/database.db',
        },
        {
            name   => 'SQLite in-memory',
            args   => {
                driver      => 'SQLite',
                driver_args => {
                    dbname => ':memory:',
                },
            },
            expect => 'dbi:SQLite:dbname=:memory:',
        },
        {
            name   => 'MySQL',
            args   => {
                driver      => 'mysql',
                driver_args => {
                    database => 'testdb',
                    host     => 'localhost',
                    port     => 3306,
                },
            },
            expect => 'dbi:mysql:database=testdb;host=localhost;port=3306',
        },
        {
            name   => 'MySQL alternative format',
            args   => {
                driver      => 'mysql',
                driver_args => [
                    'testdb',
                    'localhost',
                    3306,
                ],
            },
            expect => 'dbi:mysql:testdb:localhost:3306',
        },
        {
            name   => 'PostgreSQL',
            args   => {
                driver      => 'Pg',
                driver_args => {
                    dbname  => 'testdb',
                    host    => 'localhost',
                    port    => 5432,
                    sslmode => 'require',
                },
            },
            expect => 'dbi:Pg:dbname=testdb;host=localhost;port=5432;sslmode=require',
        },
        {
            name   => 'Oracle',
            args   => {
                driver      => 'Oracle',
                driver_args => {
                    host    => 'localhost',
                    port    => 1521,
                    sid     => 'ORCL',
                },
            },
            expect => 'dbi:Oracle:host=localhost;port=1521;sid=ORCL',
        },
        {
            name   => 'Oracle TNS',
            args   => {
                driver      => 'Oracle',
                driver_args => [
                    'ORCL',
                ]
            },
            expect => 'dbi:Oracle:ORCL',
        },
        {
            name   => 'SQL Server via DBD::ODBC',
            args   => {
                driver      => 'ODBC',
                driver_args => {
                    Database => 'testdb',
                    Driver   => '{SQL Server}',
                    Server   => 'localhost',
                },
            },
            expect => 'dbi:ODBC:Database=testdb;Driver={SQL Server};Server=localhost',
        },
    );

    foreach my $test (@tests) {
        my $config = Essentials::DB::Connection::Config->new(
            username => 'example',
            password => 'changeme',
            %{ $test->{args} }
        );
        is($config->dsn, $test->{expect}, $test->{name});
    }
};

done_testing();
