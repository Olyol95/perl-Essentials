package Essentials::Config::Driver;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;

use File::Slurper qw(read_text write_text);
use Try::Tiny;

use Essentials::Exception qw(throw);

# ABSTRACT: Role defining a driver for interacting with files of a specific format

=head1 DESCRIPTION

This package provides a L<Moo::Role> that defines a driver for reading to
and writing from files of a specific format, such as JSON.

Each supported file format will have its own driver implementation that
conforms to this role.

=head1 SYNOPSIS

  package Essentials::Config::Driver::Example;

  use Moo;

  with 'Essentials::Config::Driver';

  # implement a method for checking whether the provided MIME type is supported
  sub supports_type {
      my ($self, $mime_type_string) = @_;

      return $mime_type_string =~ /.../;
  }

  # implement a method for decoding an encoded string to a perl data ref
  sub decode {
      my ($self, $string) = @_;
      ....
      return $data;
  }

  # implement a method for encoding a perl data ref to a string
  sub encode {
      my ($self, $data) = @_;
      ....
      return $string;
  }

  1;

=head1 REQUIRED METHODS

The following methods are required in order to implement this role.

=over

=item decode($self, $string)

Given a string that is encoded in the supported format, returns a
reference to a data structure representing the decoded content.

References may be a hashref or arrayref depending on the contents
of the encoded string.

=cut

requires 'decode';

=item encode($self, $data)

Given an arrayref or hashref, returns a string that represents the
contents of the reference as encoded with the supported format.

=cut

requires 'encode';

=item supports_type($self, $mime_type_string)

Given a MIME type string (e.g. 'application/json'), returns a boolean
representing whether or not this driver can decode and encode content
of this format.

=cut

requires 'supports_type';

=back

=head1 METHODS

The following methods will be composed when using this role.

=over

=item read_from($self, $file_path)

Reads the contents of the file at C<$file_path>, decodes it and
returns a reference to the decoded data.

The reference may be a hashref or arrayref depending on the contents
of the file.

C<$file_path> should be a string containing the path to the file.

Will throw an L<Essentials::Exception> if the file does not exist,
or otherwise cannot be decoded.

=cut

sub read_from {
    my ($self, $file_path) = @_;

    throw "No file path provided" unless $file_path;

    my $data;
    try {
        $data = $self->decode(
            read_text($file_path)
        );
    }
    catch {
        throw "Error reading file '$file_path': $_";
    };

    return $data;
}

=item write_to($self, $file_path, $data)

Encodes the C<$data> reference to a string, and writes it to
disk at the C<$file_path> provided.

C<$data> may be a hashref or arrayref.

C<$file_path> should be a string containing the path to the file.

Will throw an L<Essentials::Exception> if the data cannot be encoded,
or the file cannot be written to.

=cut

sub write_to {
    my ($self, $file_path, $data) = @_;

    try {
        write_text(
            $file_path,
            $self->encode($data)
        );
    }
    catch {
        throw "Error writing to file '$file_path': $_";
    };
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Config>

=back

=cut

1;
