#!usr/bin/env perl

use v5.26;
use strictures 2;
use utf8::all;

use Test::More;

use_ok('Essentials::Config::Driver::INI');
    
my $driver = Essentials::Config::Driver::INI->new;

my @data = (
    {
        encoded => '',
        decoded => {},
    },
    {
        encoded => join("\n", (
            'array[]=5678',
            'array[]=duplicate',
            'example=1234',
            '',
            '[section]',
            'csv=1,2,3,4',
            'example=example2',
            'key=value',
            "smiley=🫠\n",
        )),
        decoded => {
            _       => {
                example => '1234',
                array   => [ '5678', 'duplicate' ],
            },
            section => {
                'csv'     => '1,2,3,4',
                'key'     => 'value',
                'example' => 'example2',
                'smiley'  => '🫠',
            },
        },
    },
);

subtest supports_type => sub {
    my %tests = (
        'text/example'    => '',
        'invalid'         => '',
        'text/ini'        => 1,
        'application/ini' => 1,
        'text/cnf+ini'    => '',
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

done_testing();
