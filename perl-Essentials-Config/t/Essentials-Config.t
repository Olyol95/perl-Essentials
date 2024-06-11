#!usr/bin/env perl

use v5.26;
use strictures 2;
use utf8::all;

use File::Slurper qw(read_text write_text);
use Safe::Isa;
use Test::Exception;
use Test::More;

use_ok('Essentials::Config');

my $config = Essentials::Config->new;

subtest select_driver => sub {
    my %tests = (
        '/path/to/example.cnf'  => 'Essentials::Config::Driver::CNF',
        '/path/to/example.ini'  => 'Essentials::Config::Driver::INI',
        '/path/to/example.json' => 'Essentials::Config::Driver::JSON',
        '/path/to/example.xml'  => 'Essentials::Config::Driver::XML',
        '/path/to/example.yml'  => 'Essentials::Config::Driver::YAML',
        '/path/to/example.yaml' => 'Essentials::Config::Driver::YAML',
    );
    foreach my $file_path (keys %tests) {
        my $driver = $config->_select_driver($file_path);
        ok(
            $driver->$_isa($tests{$file_path}),
            "Correct driver selected for '$file_path'"
        );
    }
    throws_ok {
        $config->_select_driver('/path/to/example.html');
    } 'Essentials::Exception', 'Driver not found for HTML file';
};

subtest read_file => sub {
    throws_ok {
        $config->read_file()
    } 'Essentials::Exception', 'Exception thrown when file path not provided';

    throws_ok {
        $config->read_file('/tmp/thisdoesnotexist.yaml')
    } 'Essentials::Exception', 'Exception thrown when file does not exist';

    my $file_path = _rand_tmp_file();

    my $file = write_text(
        $file_path,
        "---\nkey1: value1\nkey2: 🫠\n"
    );

    is_deeply(
        $config->read_file($file_path),
        {
            key1 => 'value1',
            key2 => '🫠',
        },
        'File read correctly',
    );
};

subtest write_file => sub {
    throws_ok {
        $config->write_file()
    } 'Essentials::Exception', 'Exception thrown when file path not provided';

    my $file_path = _rand_tmp_file();

    $config->write_file($file_path, {
        key1 => 'value1',
        key2 => '🫠',
    });

    is(
        read_text($file_path),
        "---\nkey1: value1\nkey2: 🫠\n",
        'File written correctly',
    );
};

sub _rand_tmp_file {
    return sprintf('/tmp/%08X.yaml', rand(0xffffffff));
}

done_testing();
