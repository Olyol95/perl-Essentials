package Essentials::Beanstalk::Priority;

use v5.26;
use strictures 2;

# VERSION

use Const::Fast;
use Exporter qw(import);

# ABSTRACT: Priority enums for use with Essentials::Beanstalk::Client

=head1 SYNOPSIS

  use Essentials::Beanstalk::Client;
  use Essentials::Beanstalk::Priority qw(:constants);

  my $client = Essentials::Beanstalk::Client->new;

  # add a job with low priority (i.e. will be scheduled last)
  $client->use('example_tube');
  my $job = $client->put({
      data     => { example => '1234' },
      priority => $LOW,
  });

  # add a job with high priority (i.e. will be scheduled first)
  my $job = $client->put({
     data     => { example => '4567' },
     priority =>  $HIGH,
  });

=head1 DESCRIPTION

This module exports job priority enums for use with L<Essentials::Beanstalk::Client>.

=head1 EXPORTED CONSTANTS

The following constants are exported:

=over

=item C<$HIGHEST>

The highest possible job priority, will be reserved before all other
priority levels.

Value: 0

=item C<$HIGH>

Value: 250

=item C<$MEDIUM>

Value: 500

=item C<$LOW>

Value: 750

=item C<$LOWEST>

The lowest possible job priority, will be reserved after all other
priority levels.

Value: 1000

=back

The above constants can all be imported at once via the C<:constants> tag.

=cut

our %EXPORT_TAGS = (
    constants => [qw(
        $HIGHEST
        $HIGH
        $MEDIUM
        $LOW
        $LOWEST
    )],
);

our @EXPORT_OK = (
    @{ $EXPORT_TAGS{constants} },
);

const our $HIGHEST => 0;
const our $HIGH    => 250;
const our $MEDIUM  => 500;
const our $LOW     => 750;
const our $LOWEST  => 1000;

=head1 SEE ALSO

=over

=item L<Essentials::Beanstalk::Client>

=item L<Essentials::Beanstalk::Producer>

=item L<Essentials::Beanstalk::Consumer>

=back

=cut

1;
