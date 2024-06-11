#!usr/bin/env perl

use v5.26;
use strictures 2;
use utf8::all;

use Test::More;
use Tie::IxHash;

use_ok('Essentials::Config::Driver::CNF');
    
my $driver = Essentials::Config::Driver::CNF->new;

my @data = (
    {
        encoded => '',
        decoded  => {},
    },
    {
        encoded => join("\n", (
            'example   1234',
            'array   5678',
            'array   duplicate',
            '<section>',
            '    csv   1,2,3,4',
            '    key   value',
            '    example   example2',
            '    smiley   🫠',
            "</section>\n",
        )),
        decoded => ordered_hash(
            example => '1234',
            array   => [ '5678', 'duplicate' ],
            section => ordered_hash(
                'csv'     => '1,2,3,4',
                'key'     => 'value',
                'example' => 'example2',
                'smiley'  => '🫠',
            ),
        ),
    },
);

subtest supports_type => sub {
    my %tests = (
        'text/example'    => '',
        'invalid'         => '',
        'text/cnf'        => 1,
        'application/cnf' => 1,
        'text/json+cnf'   => '',
    );
    foreach my $type (keys %tests) {
        is(
            $driver->supports_type($type),
            $tests{$type},
            "supports_type correct for '$type'"
        );
    }
};

subtest decode => sub {
    foreach my $test (@data) {
        is_deeply(
            $driver->decode($test->{encoded}),
            $test->{decoded},
            "Data decoded correctly"
        );
    }
};

subtest encode => sub {
    foreach my $test (@data) {
        is_deeply(
            $driver->encode($test->{decoded}),
            $test->{encoded},
            "Data encoded correctly"
        );
    }
};

sub ordered_hash {
    my @args = @_;

    my %hash;
    tie(%hash, 'Tie::IxHash', @args);

    return \%hash;
}

done_testing();
