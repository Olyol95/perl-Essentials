#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Capture::Tiny qw(capture_stderr);
use File::Basename;
use File::Slurp;
use Test::Exception;
use Test::More;

use_ok('Essentials::Log::Writer');

subtest write => sub {
    subtest stderr => sub {
        my $line = capture_stderr {
            my $writer = Essentials::Log::Writer->new;
            $writer->write('Example message');
        };
        is($line, "Example message\n", 'STDERR set by default');
    };

    subtest file => sub {
        my $dir = dirname($0);

        subtest die_on_missing_dir => sub {
            throws_ok {
                Essentials::Log::Writer->new(
                    filename => 'thisdoesnotexist/example.txt',
                );
            } qr/Error opening/, 'Error thrown for nonexistent dir'
        };

        subtest die_on_read_only => sub {
            my $file_name = "$dir/read_only.log";
            create_file(
                $file_name, '', 1,
            );
            throws_ok {
                Essentials::Log::Writer->new(
                    filename => $file_name,
                );
            } qr/Error opening/, 'Error thrown for readonly file';
            unlink $file_name;
        };

        subtest create_file => sub {
            my $file_name = "$dir/create_file.log";
            ok(!-e $file_name, 'File does not exist');
            my $writer = Essentials::Log::Writer->new(
                filename => $file_name,
            );
            $writer->write('Example message');
            ok(-e $file_name, 'File created');
            is(
                read_file($file_name),
                "Example message\n",
                'File written to successfully'
            );
            unlink $file_name;
        };

        subtest append_file => sub {
            my $file_name = "$dir/append_file.log";
            create_file(
                $file_name,
                "Pre-existing text\n"
            );
            my $writer = Essentials::Log::Writer->new(
                filename => $file_name,
            );
            $writer->write('New message');
            is(
                read_file($file_name),
                "Pre-existing text\nNew message\n",
                'File appended to successfully'
            );
            unlink $file_name;
        };
    };
};

done_testing();

sub create_file {
    my ($file_name, $text, $readonly) = @_;

    open my $fh, '>', $file_name;
    print $fh $text;
    close $fh;
    ok(-e $file_name, 'File exists');
    is(
        read_file($file_name),
        $text,
        'File created successfully'
    );

    if ($readonly) {
        chmod 0400, $file_name;
        ok(!-w $file_name, 'File not writable');
    }
}
