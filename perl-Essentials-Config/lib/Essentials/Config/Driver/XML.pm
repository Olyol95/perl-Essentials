package Essentials::Config::Driver::XML;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use XML::Simple;

with 'Essentials::Config::Driver';

# ABSTRACT: Driver for interacting with XML files

=head1 DESCRIPTION

A driver for L<Essentials::Config> for decoding and encoding
application configuration stored in XML format.

=head1 SYNOPSIS

  use Essentials::Config::Driver::XML;

  my $driver = Essentials::Config::Driver::XML->new;

  # check if the mime type is supported by the driver
  my $supported = $driver->supports_type('application/xml')

  # write data to the given file path
  $driver->write_to('/path/to/file.xml', {
      option => 'value',
  });

=head1 METHODS

See the methods provided by L<Essentials::Config::Driver>.

=cut

has '_xml' => (
    is      => 'lazy',
    default => sub {
        XML::Simple->new
    },
);

sub supports_type {
    my ($self, $type) = @_;

    return $type =~ /^[^\/]+\/xml$/i;
}

sub decode {
    my ($self, $data) = @_;

    unless ($data) {
        return {};
    }

    return $self->_xml->XMLin($data);
}

sub encode {
    my ($self, $data) = @_;

    return $self->_xml->XMLout($data);
}

=head1 SEE ALSO

=over

=item L<Essentials::Config>

=item L<Essentials::Config::Driver>

=back

=cut

1;
