package Essentials::Script::Heartbeat::None;

use v5.26;
use strictures 2;

# VERSION

use Moo;

with 'Essentials::Script::Heartbeat';

# ABSTRACT: A heartbeat module that does nothing when notified

=head1 SYNOPSIS

  use Essentials::Script::Heartbeat::None;

  my $heartbeat = Essentials::Script::Heartbeat::None->new;

  # do some work

  # notify that we're still alive
  $heartbeat->notify;

=head1 DESCRIPTION

This package provides a heartbeat handler for instances of L<Essentials::Script>
and L<Essentials::Script::Service> which does nothing when notified.

It isn't very useful on its own, but can be used as a sensible default.

=head1 METHODS

=over

=item C<notify>

Consumes the notification without doing anything.

Always returns 1;

=cut

sub notify {
    return 1;
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script>

=item L<Essentials::Script::Heartbeat>

=back

=cut

1;
