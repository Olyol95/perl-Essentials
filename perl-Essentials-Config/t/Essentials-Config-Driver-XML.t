#!usr/bin/env perl

use v5.26;
use strictures 2;
use utf8::all;

use Test::More;

use_ok('Essentials::Config::Driver::XML');
    
my $driver = Essentials::Config::Driver::XML->new;

my @data = (
    {
        encoded => "<opt></opt>\n",
        decoded => {},
    },
    {
        encoded => join("\n", (
            '<opt example="1234">',
            '  <array>5678</array>',
            '  <array>duplicate</array>',
            '  <section key="value" csv="1,2,3,4" example="example2" smiley="🫠" />',
            "</opt>\n",
        )),
        decoded => {
            example => '1234',
            array   => [ '5678', 'duplicate' ],
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
        'text/example'        => '',
        'invalid'             => '',
        'text/xml'            => 1,
        'application/xml'     => 1,
        'application/x-xml'   => '',
        'application/rss+xml' => '',
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
