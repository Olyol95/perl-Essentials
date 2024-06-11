package Essentials::Config::Driver::INI;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use Config::Tiny;
use Data::Structure::Util qw(unbless);

with 'Essentials::Config::Driver';

# ABSTRACT: Driver for interacting with INI files

=head1 DESCRIPTION

A driver for L<Essentials::Config> for decoding and encoding
application configuration stored in INI format.

=head1 SYNOPSIS

  use Essentials::Config::Driver::INI;

  my $driver = Essentials::Config::Driver::INI->new;

  # check if the mime type is supported by the driver
  my $supported = $driver->supports_type('text/ini')

  # write data to the given file path
  $driver->write_to('/path/to/file.ini', {
      option => 'value',
  });

=head1 METHODS

See the methods provided by L<Essentials::Config::Driver>.

=cut

sub supports_type {
    my ($self, $type) = @_;

    return $type =~ /^[^\/]+\/ini$/i;
}

sub decode {
    my ($self, $data) = @_;

    my $conf = Config::Tiny->new->read_string($data);

    if ($conf) {
        return unbless $conf;
    }

    return {};
}

sub encode {
    my ($self, $data) = @_;

    return Config::Tiny->new($data)->write_string;
}

=head1 SEE ALSO

=over

=item L<Essentials::Config>

=item L<Essentials::Config::Driver>

=back

=cut

1;
