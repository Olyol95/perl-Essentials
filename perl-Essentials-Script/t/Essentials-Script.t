#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::MockFile;
use Test::MockModule;
use Test::More;

use Essentials::Log::Level qw($INFO);
use Essentials::Script::Heartbeat::StampFile;

my $pod2usage_called;
my $mock = Test::MockModule->new('Pod::Usage');
$mock->mock('pod2usage', sub {
    $pod2usage_called = 1;
});

use_ok('Essentials::Script');

{
    package Essentials::Script::Test;

    use Moo;

    with 'Essentials::Script';

    has 'example_string' => (
        is       => 'ro',
        required => 1,
    );

    has 'example_int' => (
        is       => 'ro',
        required => 1,
    );

    has 'example_array' => (
        is       => 'ro',
        required => 1,
    );

    has 'example_bool' => (
        is => 'ro',
    );

    sub run {
        return 1;
    }

    1;
}

subtest new_with_opts => sub {
    ## no critic
    @ARGV = (
        '--string=foo',
        '-n=5',
        '--array=one',
        '--array=two',
        '--log-level=info',
    );
    ## use critic
    my $script = Essentials::Script::Test->new_with_opts(
        example_string => 'string=s',
        example_int    => 'number|n=i',
        example_array  => 'array=s@',
        example_bool   => 'true-if-present',
    );
    is($script->example_string, 'foo', 'string attribute set correctly');
    is($script->example_int, '5', 'integer attribute set correctly');
    is_deeply($script->example_array, ['one', 'two'], 'array attribute set correctly');
    is($script->example_bool, undef, 'boolean attribute set correctly');

    ok($script->log->$_isa('Essentials::Log'), 'logger instantiated correctly');
    is($script->log->level, $INFO, 'log level passed through correctly');

    ok($script->heartbeat->$_isa('Essentials::Script::Heartbeat::None'), 'heartbeat instantiated correctly');
};

subtest help => sub {
    ## no critic
    @ARGV = (
        '--string=foo',
        '-n=5',
        '--array=one',
        '--array=two',
        '--help',
    );
    ## use critic
    ok(!$pod2usage_called, 'pod2usage not yet called');
    my $script = Essentials::Script::Test->new_with_opts(
        example_string => 'string=s',
        example_int    => 'number|n=i',
        example_array  => 'array=s@',
        example_bool   => 'true-if-present',
    );
    ok($pod2usage_called, 'pod2usage called when --help parameter provided');
};

subtest heartbeat => sub {
    my $heartbeat = Essentials::Script::Heartbeat::StampFile->new(
        file_name => 'example.stamp'
    );
    my $file = Test::MockFile->file($heartbeat->file_name);
    ## no critic
    @ARGV = (
        '--string=foo',
        '-n=5',
        '--array=one',
        '--array=two',
        '--help',
    );
    ## use critic
    my $script = Essentials::Script::Test->new_with_opts(
        example_string => 'string=s',
        example_int    => 'number|n=i',
        example_array  => 'array=s@',
        example_bool   => 'true-if-present',
    )
    ->with_heartbeat($heartbeat);
    ok(!-f $heartbeat->file_name, 'stamp file not yet created');
    $script->run;
    ok(-f $heartbeat->file_name, 'stamp file created after execution');
};

done_testing();
