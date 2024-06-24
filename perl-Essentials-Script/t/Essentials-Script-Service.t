#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Safe::Isa;
use Test::More;

use_ok('Essentials::Script::Service');

{
    package Essentials::Script::Service::Test;

    use Moo;

    with 'Essentials::Script::Service';

    has iters => (
        is      => 'rw',
        default => 0,
    );

    sub run {
        my $self = shift;

        $self->iters($self->iters + 1);

        return $self->iters;
    }

    1;
}

subtest composes_script => sub {
    my $service = Essentials::Script::Service::Test->new;
    ok($service->$_does('Essentials::Script'), 'composes Essentials::Script');
};

subtest min_interval => sub {
    subtest default => sub {
        my $service = Essentials::Script::Service::Test->new;
        local $SIG{ALRM} = sub { $service->stop };
        my $start = time;
        alarm 1;
        $service->start;
        ok($service->iters > 2, 'more than two iterations');
        my $stop = time;
        ok($stop - $start >= 1, 'took at least one second');
    };

    subtest override => sub {
        my $service = Essentials::Script::Service::Test->new->with_min_interval(2);
        local $SIG{ALRM} = sub { $service->stop };
        my $start = time;
        alarm 3;
        $service->start;
        is($service->iters, 2, 'two iterations');
        my $stop = time;
        ok($stop - $start >= 3, 'took three seconds');
    };
};

done_testing();
