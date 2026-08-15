package Essentials::Script;

use v5.26;
use strictures 2;

# VERSION

use Getopt::Long;
use Moo::Role;
use Pod::Usage;
use Try::Tiny;

use Essentials::Log::Level qw(from_string $WARN);

with 'Essentials::Log::Attribute';
with 'Essentials::Script::Heartbeat::Attribute';

# ABSTRACT: A Moo role for wrapping scripts as modules

=head1 SYNOPSIS

In C<My/Application.pm>

  package My::Application;

  use Moo;

  with 'Essentials::Script';

  has 'example_string' => (
      ...
  );

  has 'example_int' => (
      ...
  );

  has 'example_array' => (
      ...
  );

  has 'example_bool' => (
      ...
  );

  sub run {
      # implementation here...
  }

  1;

In C<my-script.pl>

  #!/usr/bin/env perl

  use My::Application;
  use Essentials::Script::Heartbeat::StampFile;

  My::Application->new_with_opts(
      example_string => 'example-string=s',
      example_int    => 'baz=i',
      example_array  => 'array-item=s@',
      example_bool   => 'bool',
  )
  ->with_heartbeat(
      Essentials::Script::Heartbeat::StampFile->new(
          file_name => '/path/to/stamp-file.stamp',
      ),
  )
  ->run;

=head1 DESCRIPTION

This package provides a L<Moo::Role> for wrapping a L<Moo> object with a
C<new_with_opts> constructor that populates attributes from command-line
options via L<Getopt::Long> argument strings.

In addition to your own custom arguments, this role provides the following
CLI options by default:

=over

=item C<log-level E<lt>levelE<gt>>

The verbosity level to use for logging. Defaults to C<warn>.

Valid options are C<trace>, C<debug>, C<info>, C<warn>, C<error>.

=item C<help>

Displays usage text.

=back

=head1 ATTRIBUTES

This role also provides some default attributes.

=over

=item C<log>

An instance of L<Essentials::Log>.

The log level can be configured via the C<log-level> CLI argument,
and will default to C<warn>.

=item C<heartbeat>

An instance of L<Essentials::Script::Heartbeat>, which will be notified
after each successful execution of the C<run> method.

Defaults to L<Essentials::Script::Heartbeat::None>.

=back

=head1 REQUIRED METHODS

The following methods require implementation in order to compose the role.

=over

=item C<run>

The entry point for your script.

There are no restrictions on the parameters that can be passed to this method,
though it is recommended that you use attributes instead to keep as much logic
inside a module as possible so that it can be more easily tested.

=cut

requires 'run';

around run => sub {
    my ($orig, $self, @args) = @_;

    try {
        $orig->($self, @args);
    }
    catch {
        $self->log->error($_);
        exit 255;
    };
};

after run => sub {
    my $self = shift;

    $self->heartbeat->notify;
};

=back

=head1 STATIC METHODS

=over

=item C<new_with_opts(%opts)>

Constructs a new instance of your class with attributes populated from the
command-line options provided by the caller.

C<%opts> should be a hash that maps attribute names to L<Getopt::Long> argument
strings that will be used to populate the value of the provided attribute.

For example, a string attribute, C<full_name>,can be passed through from the
command line like so:

  My::Application->new_with_opts(
      full_name => 'full-name=s',
  );

The caller would then invoke the script like so:

  ./my-script.pl --full-name=Oliver Youle

See the documentation for L<Getopt::Long> for a complete description of the
available options.

Arrays must be provided using the array reference syntax, C<array-param=s@>.

=cut

sub new_with_opts {
    my ($package, %opts) = @_;

    my %args = map { $_ => undef } keys %opts;
    my %tmp  = map { $opts{$_} => \$args{$_} } keys %args;

    GetOptions(
        %tmp,
        'log-level=s' => \my $level,
        'help'        => \my $help,
    );

    if ($help) {
        pod2usage( -verbose => 1 );
    }

    foreach my $opt (keys %args) {
        delete $args{$opt} unless defined $args{$opt};
    }

    return $package->new(
        %args,
        log => Essentials::Log->new(
            level          => $level ? from_string($level) : $WARN,
            should_capture => 1,
        ),
    );
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script::Service>

=back

=cut

1;
