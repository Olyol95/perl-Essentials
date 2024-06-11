package Essentials::Log::Attribute;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;

use Essentials::Log;

# ABSTRACT: A Moo role for providing a log attribute

=head1 SYNOPSIS

  use Moo;

  with 'Essentials::Log::Attribute';

  sub example {
      my $self = shift;

      $self->log->info("It's working!");
  }

=head1 DESCRIPTION

This role provides a C<log> attribute which defaults to
an instance of L<Essentials::Log>.

=cut

has log => (
    is      => 'lazy',
    default => sub {
        Essentials::Log->new
    },
);

=head1 SEE ALSO

=over

=item L<Essentials::Log>

=back

=cut

1;
