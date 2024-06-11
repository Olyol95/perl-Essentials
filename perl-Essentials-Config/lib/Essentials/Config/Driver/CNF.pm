package Essentials::Config::Driver::CNF;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use Config::General;

with 'Essentials::Config::Driver';

# ABSTRACT: Driver for interacting with CNF files

=head1 DESCRIPTION

A driver for L<Essentials::Config> for decoding and encoding
application configuration stored in CNF format.

=head1 SYNOPSIS

  use Essentials::Config::Driver::CNF;

  my $driver = Essentials::Config::Driver::CNF->new;

  # check if the mime type is supported by the driver
  my $supported = $driver->supports_type('text/cnf')

  # write data to the given file path
  $driver->write_to('/path/to/file.cnf', {
      option => 'value',
  });

=head1 METHODS

See the methods provided by L<Essentials::Config::Driver>.

=cut

sub supports_type {
    my ($self, $type) = @_;

    return $type =~ /^[^\/]+\/cnf$/i;
}

sub decode {
    my ($self, $data) = @_;

    my $config = Config::General->new(
        -String => $data,
        -Tie    => 'Tie::IxHash',
    );

    return { $config->getall };
}

sub encode {
    my ($self, $data) = @_;

    my $config = Config::General->new(
        -ConfigHash => $data,
        -Tie        => 'Tie::IxHash',
    );

    return $config->save_string;
}

=head1 SEE ALSO

=over

=item L<Essentials::Config>

=item L<Essentials::Config::Driver>

=back

=cut

1;
