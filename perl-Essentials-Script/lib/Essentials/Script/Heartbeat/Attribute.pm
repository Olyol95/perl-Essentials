package Essentials::Script::Heartbeat::Attribute;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;

use Essentials::Script::Heartbeat::None;

# ABSTRACT: A Moo role for providing a heartbeat attribute

=head1 SYNOPSIS

  use Moo;

  with 'Essentials::Script::Heartbeat::Attribute';

  sub example {
      my $self = shift;

      $self->heartbeat->notify;
  }

=head1 DESCRIPTION

This role provides a C<heartbeat> attribute which defaults to
an instance of L<Essentials::Script::Heartbeat::None>.

=cut

has heartbeat => (
    is      => 'rwp',
    lazy    => 1,
    default => sub {
        Essentials::Script::Heartbeat::None->new
    },
);

=head1 METHODS

=over

=item C<with_heartbeat($heartbeat)>

Sets the the C<heartbeat> attribute to the value provided.

Returns an instance of the object composing this role, for use
in a chained builder pattern:

  my $obj = Implements::Role->some_static_builder(
      ...
  )
  ->with_heartbeat(
      Essentials::Script::Heartbeat::AutoDetect->new(...),
  );

C<$heartbeat> must compose L<Essentials::Script::Heartbeat>.

=cut

sub with_heartbeat {
    my ($self, $heartbeat) = @_;

    $self->_set_heartbeat($heartbeat);

    return $self;
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script::Heartbeat>

=back

=cut

1;
