package Essentials::Script::Heartbeat::Systemd;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use Systemd::Daemon;

with 'Essentials::Script::Heartbeat';

# ABSTRACT: A heartbeat module that forwards notifications to the systemd watchdog

=head1 SYNOPSIS

  use Essentials::Script::Heartbeat::Systemd;

  my $heartbeat = Essentials::Script::Heartbeat::Systemd->new;

  # do some work

  # notify the watchdog that we're still alive
  $heartbeat->notify;

=head1 DESCRIPTION

This package provides a heartbeat handler for instances of L<Essentials::Script>
and L<Essentials::Script::Service> which notifies the systemd watchdog.

=head1 METHODS

=over

=item C<notify>

Notifies the systemd watchdog.

Returns true if the operation was successful, false otherwise.

=cut

sub notify {
    my $self = shift;

    return Systemd::Daemon::notify(
        WATCHDOG => 1,
    ) > 0;
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script>

=item L<Essentials::Script::Heartbeat>

=back

=cut

1;
