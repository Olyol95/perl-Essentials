#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::More;
use Test::Exception;

{
    package Essentials::DB::Connection::Test;

    use Moo;

    with 'Essentials::DB::Connection';

    has calls => (
        is      => 'rw',
        default => 0,
    );

    sub txn_do {
        my ($self, $coderef) = @_;
        $self->calls($self->calls + 1);
        return $coderef->();
    }

    1;
}

subtest txn => sub {
    my $conn = Essentials::DB::Connection::Test->new;

    my $scalar = $conn->txn(sub{
        my $c = shift;
        ok($c->$_isa('Essentials::DB::Connection::Test'), 'connection passed in as first parameter');
        return 10;
    });

    is($conn->calls, 1, 'txn_do called once');
    is($scalar, 10, 'scalar return value is correct');

    my @arr = $conn->txn(sub{
        my @value = (1, 2, 3);
        return @value;
    });

    is($conn->calls, 2, 'txn_do called twice');
    is(scalar @arr, 3, 'array return value length is correct');
    for my $idx (0..2) {
        is($arr[$idx], $idx + 1, "array return value at index $idx is correct");
    }

    throws_ok {
        $conn->txn(sub {
            die "fatal error!";
        });
    } 'Essentials::Exception', 'Exception is wrapped in Essentials::Exception';
};


done_testing();
