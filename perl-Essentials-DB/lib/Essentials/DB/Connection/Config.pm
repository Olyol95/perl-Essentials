package Essentials::DB::Connection::Config;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use Types::Standard qw(HashRef ArrayRef Str);

# ABSTRACT: Configuration for Essentials::DB connections

=head1 SYNOPSIS

  use DBI;
  use Essentials::DB;
  use Essentials::DB::Connection::Config;

  # configuration for a connection to a MySQL database
  my $config = Essentials::DB::Connection::Config->new(
      username    => 'example',
      password    => 'changeme',
      driver      => 'mysql',
      driver_args => {
          database => 'testdb',
          hostname => 'testdb.example.com',
          port     => 12345,
      },
  );

  # generate a DBI DSN and connect to the database
  my $dbh = DBI->connect(
      $config->dsn,
      $config->username,
      $config->password,
  );

  # or use Essentials::DB
  my $db = Essentials::DB->new(package => 'MyApp::DB');

  $db->package->load_namespaces(...);

  my $dbh = $db->connect($config);

=head1 DESCRIPTION

A data object for storing configuration for L<DBI> database connections.

Used by L<Essentials::DB> and L<Essentials::DB::Pool>.

=head1 ATTRIBUTES

=head3 driver

The name of the DBI driver to use, e.g. C<mysql>.

Required.

=cut

has driver => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head3 driver_args

Driver-specific arguments, such as C<hostname>.

Key-value style arguments should be specified as a hashref, which can be
used to express DSN's of the following format:

  scheme:driver:key=value;foo=bar

This is the preferred format for most drivers.

Positional arguments can be specified as an arrayref instead, if you
need to generate a DSN such as this:

  scheme:driver:value:bar

Required.

=cut

has driver_args => (
    is       => 'ro',
    isa      => HashRef|ArrayRef,
    required => 1,
);

=head3 password

The password for the provided username.

Required.

=cut

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head3 username

The username to connect to the database with.

Required.

=cut

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head1 METHODS

=head3 C<dsn()>

Generates and returns a L<DBI>-compatible DSN string.

=cut

has dsn => (
    is      => 'lazy',
    default => sub {
        my $self = shift;

        my @driver_args;
        if (ref $self->driver_args eq 'HASH') {
            @driver_args = map {
                join('=', $_, $self->driver_args->{$_})
            } sort keys %{ $self->driver_args };
        }
        else {
            @driver_args = (join(':', @{ $self->driver_args }));
        }

        return join(':',
            'dbi',
            $self->driver,
            join(';', @driver_args),
        );
    },
);

=head1 SEE ALSO

=over

=item L<Essentials::DB>

=item L<Essentials::DB::Pool>

=item L<DBI>

=back

=cut

1;
