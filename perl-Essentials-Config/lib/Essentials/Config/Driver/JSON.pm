package Essentials::Config::Driver::JSON;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use JSON::XS;

with 'Essentials::Config::Driver';

# ABSTRACT: Driver for interacting with JSON files

=head1 DESCRIPTION

A driver for L<Essentials::Config> for decoding and encoding
application configuration stored in JSON format.

=head1 SYNOPSIS

  use Essentials::Config::Driver::JSON;

  my $driver = Essentials::Config::Driver::JSON->new;

  # check if the mime type is supported by the driver
  my $supported = $driver->supports_type('application/json')

  # write data to the given file path
  $driver->write_to('/path/to/file.json', {
      option => 'value',
  });

=head1 METHODS

See the methods provided by L<Essentials::Config::Driver>.

=cut

has '_json' => (
    is      => 'lazy',
    default => sub {
        JSON::XS->new->pretty
    },
);

sub supports_type {
    my ($self, $type) = @_;

    return $type =~ /^[^\/]+\/(x-)?json$/i;
}

sub decode {
    my ($self, $data) = @_;

    return $self->_json->decode($data);
}

sub encode {
    my ($self, $data) = @_;

    return $self->_json->encode($data);
}

=head1 SEE ALSO

=over

=item L<Essentials::Config>

=item L<Essentials::Config::Driver>

=back

=cut

1;
