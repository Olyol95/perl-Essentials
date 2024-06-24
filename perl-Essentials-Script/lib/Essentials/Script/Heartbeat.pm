package Essentials::Script::Heartbeat;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;

# ABSTRACT: A Moo role for modules that provide a heartbeat for a script or service

=head1 SYNOPSIS

  use Moo;

  with 'Essentials::Script::Heartbeat';

  # This method will be called whenever the script or service executes successfully
  sub notify {
      my $self = shift;

      # do something useful, like writing to a file or pushing an event to a stream
      # which can then be consumed by a health check
  }

=head1 DESCRIPTION

This package provides a L<Moo::Role> for implementing a heartbeat handler
for instances of L<Essentials::Script> and L<Essentials::Script::Service>.

The handler will be notified at regular intervals for a service, or upon
successful execution of a script, and should be used to record information
that can be consumed by a health check.

=head1 REQUIRED METHODS

The following methods require implementation in order to compose the role.

=over

=item C<notify>

This method will be invoked whenever an L<Essentials::Script::Service>
completes a successful iteration, or when an L<Essentials::Script> executes
successfully.

You can then implement your own logic to update the application or system
state in such a way that a health check can determine that the script or
service is operating correctly.

The method should return a truthy value if notification was successful,
and false otherwise.

=cut

requires 'notify';

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script>

=item L<Essentials::Script::Service>

=item L<Essentials::Script::Heartbeat::StampFile>

=item L<Essentials::Script::Heartbeat::Systemd>

=back

=cut

1;
