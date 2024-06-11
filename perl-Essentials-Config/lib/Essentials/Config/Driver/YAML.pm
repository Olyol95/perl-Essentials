package Essentials::Config::Driver::YAML;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use YAML::PP;

with 'Essentials::Config::Driver';

# ABSTRACT: Driver for interacting with YAML files

=head1 DESCRIPTION

A driver for L<Essentials::Config> for decoding and encoding
application configuration stored in YAML format.

=head1 SYNOPSIS

  use Essentials::Config::Driver::YAML;

  my $driver = Essentials::Config::Driver::YAML->new;

  # check if the mime type is supported by the driver
  my $supported = $driver->supports_type('text/yaml')

  # write data to the given file path
  $driver->write_to('/path/to/file.yaml', {
      option => 'value',
  });

=head1 METHODS

See the methods provided by L<Essentials::Config::Driver>.

=cut

has _yaml => (
    is      => 'lazy',
    default => sub {
        YAML::PP->new
    },
);

sub supports_type {
    my ($self, $type) = @_;

    return $type =~ /^[^\/]+\/(x-)?yaml$/i;
}

sub decode {
    my ($self, $data) = @_;

    return $self->_yaml->load_string($data) || {};
}

sub encode {
    my ($self, $data) = @_;

    return $self->_yaml->dump_string($data);
}

=head1 SEE ALSO

=over

=item L<Essentials::Config>

=item L<Essentials::Config::Driver>

=back

=cut

1;
