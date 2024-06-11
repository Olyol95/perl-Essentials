#!usr/bin/env perl

use v5.26;
use strictures 2;
use utf8::all;

use Test::More;
use Tie::IxHash;

use_ok('Essentials::Config::Driver::YAML');
    
my $driver = Essentials::Config::Driver::YAML->new;

my @data = (
    {
        encoded => "--- {}\n",
        decoded => {},
    },
    {
        encoded => "--- []\n",
        decoded => [],
    },
    {
        encoded => join("\n", (
            '---',
            'array:',
            '- \'5678\'',
            '- duplicate',
            'example: 1234',
            'section:',
            '  csv: 1,2,3,4',
            '  example: example2',
            '  key: value',
            '  smiley: 🫠',
            '',
        )),
        decoded => {
            array   => [ '5678', 'duplicate' ],
            example => 1234,
            section => {
                'csv'     => '1,2,3,4',
                'example' => 'example2',
                'key'     => 'value',
                'smiley'  => '🫠',
            },
        },
    },
);

subtest supports_type => sub {
    my %tests = (
        'text/example'       => '',
        'invalid'            => '',
        'text/yaml'          => 1,
        'application/yaml'   => 1,
        'application/x-yaml' => 1,
        'text/xml+yaml'      => '',
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
