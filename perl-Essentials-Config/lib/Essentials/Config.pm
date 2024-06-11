package Essentials::Config;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use File::MimeInfo;
use Module::Find;

use Essentials::Exception qw(throw);

# ABSTRACT: A library for managing config files in various common formats

=head1 SYNOPSIS

  use Essentials::Config;

  my $config = Essentials::Config->new;

  # load data from a YAML file
  my $data = $config->read_file('/path/to/file.yaml');

  # make some transformations...
  $data->{example} = 'new value';

  # save the data as JSON
  #config->write_file('/path/to/file.json', $data);

=head1 DESCRIPTION

This module provides methods for reading and writing to files of
various formats commonly used for application configuration.

The underlying driver is selected automatically based on the
extension of the file path provided.

Supported formats:

=over

=item CNF

=item INI

=item JSON

=item XML

=item YAML

=back

=cut

has _drivers => (
    is      => 'ro',
    default => sub {
        my @drivers;

        my @modules = usesub 'Essentials::Config::Driver';
        foreach my $module (@modules) {
            push @drivers, $module->new;
        }

        return \@drivers;
    },
);

=head1 METHODS

=over

=item C<read_file($file_path)>

Reads the contents of the file at the path provided and returns
the decoded contents as a hashref or arrayref (depending on the
file contents).

C<$file_path> is a string containing the path of the file to read.

The encoding of the file is determined automatically.

=cut

sub read_file {
    my ($self, $file_path) = @_;

    throw "No file path provided" unless $file_path;

    return $self->_select_driver($file_path)->read_from($file_path);
}

=item C<write_file($file_path, $data)>

Writes the C<$data> provided to a file at the provided C<$file_path>,
encoding the data based on the extension of the file provided.

C<$data> is an arrayref or hashref.

C<$file_path> is a string containing the path of the file to write to.

=cut

sub write_file {
    my ($self, $file_path, $data) = @_;

    throw "No file path provided" unless $file_path;

    $self->_select_driver($file_path)->write_to($file_path, $data);
}

sub _select_driver {
    my ($self, $file_path) = @_;

    throw "No file path provided" unless $file_path;

    my $mime_type = $self->_mime_type($file_path);

    foreach my $driver (@{ $self->_drivers }) {
        return $driver if $driver->supports_type($mime_type);
    }

    throw "No available driver found for '$mime_type'";
}

sub _mime_type {
    my ($self, $file_path) = @_;

    throw "No file path provided" unless $file_path;

    state %overrides = (
        qr/[.]ini$/ => 'application/ini',
        qr/[.]cnf$/ => 'application/cnf',
    );

    foreach my $pattern (keys %overrides) {
        return $overrides{$pattern} if $file_path =~ $pattern;
    }

    return mimetype($file_path);
}

=back

=cut

1;
