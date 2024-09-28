#!/usr/bin/env perl

use v5.26;
use strictures 2;

use Test::More;

use_ok('Essentials::Beanstalk::Priority', qw($HIGHEST $HIGH $MEDIUM $LOW $LOWEST));

subtest values => sub {
    is($Essentials::Beanstalk::Priority::HIGHEST, 0,    '$HIGHEST is 0');
    is($Essentials::Beanstalk::Priority::HIGH,    250,  '$HIGH is 250');
    is($Essentials::Beanstalk::Priority::MEDIUM,  500,  '$MEDIUM is 500');
    is($Essentials::Beanstalk::Priority::LOW,     750,  '$LOW is 750');
    is($Essentials::Beanstalk::Priority::LOWEST,  1000, '$LOWEST is 1000');
};

subtest ordering => sub {
    ok($Essentials::Beanstalk::Priority::HIGHEST < $Essentials::Beanstalk::Priority::HIGH,   '$HIGHEST < $HIGH');
    ok($Essentials::Beanstalk::Priority::HIGH    < $Essentials::Beanstalk::Priority::MEDIUM, '$HIGH < $MEDIUM');
    ok($Essentials::Beanstalk::Priority::MEDIUM  < $Essentials::Beanstalk::Priority::LOW,    '$MEDIUM < $LOW');
    ok($Essentials::Beanstalk::Priority::LOW     < $Essentials::Beanstalk::Priority::LOWEST, '$LOW < $LOWEST');
};

subtest individual_exports => sub {
    Essentials::Beanstalk::Priority->import(qw($HIGHEST $HIGH $MEDIUM $LOW $LOWEST));
    ## no critic
    is($main::HIGHEST, 0,    'imported $HIGHEST is 0');
    is($main::HIGH,    250,  'imported $HIGH is 250');
    is($main::MEDIUM,  500,  'imported $MEDIUM is 500');
    is($main::LOW,     750,  'imported $LOW is 750');
    is($main::LOWEST,  1000, 'imported $LOWEST is 1000');
    ## use critic
};

subtest constants_tag => sub {
    Essentials::Beanstalk::Priority->import(':constants');
    ## no critic
    is($main::HIGHEST, 0,    ':constants tag imports $HIGHEST');
    is($main::LOWEST,  1000, ':constants tag imports $LOWEST');
    ## use critic
};

done_testing();
