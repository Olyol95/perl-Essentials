package Essentials::Log::Level;

use v5.26;
use strictures 2;

# VERSION

use Const::Fast;
use Exporter qw(import);
use Scalar::Util qw(dualvar);

use Essentials::Exception qw(throw);

our %EXPORT_TAGS = (
    constants => [qw(
        $TRACE
        $DEBUG
        $INFO
        $WARN
        $ERROR
    )],
);

our @EXPORT_OK = (
    @{ $EXPORT_TAGS{constants} },
    qw(
        from_string
    )
);

# ABSTRACT: Verbosity level constants for Essentials::Log

=head1 SYNOPSIS

  use Essentials::Log;
  use Essentials::Log::Level qw($DEBUG, $INFO, from_string);

  my $log = Essentials::Log->new(
      level => $DEBUG,
  );

  $log->debug("Now you see me");

  $log->level($INFO);

  $log->debug("Now you don't!");

  my $info_level  = from_string('info');

  # levels can be compared as integers
  if ($info_level > $ERROR) { ... }

  # and have a human-readable name in string context
  say $info_level; # prints 'info'

=head1 DESCRIPTION

This module exports a set of constants that represent the various
severity levels supported by L<Essentials::Log>.

The available levels are as follows, in increasing order of severity:

=over

=item C<$TRACE> - The lowest level, reserved for extremely verbose output

=cut

const our $TRACE => dualvar(1, 'trace');

=item C<$DEBUG> - Verbose output generally only useful for testing

=cut

const our $DEBUG => dualvar(2, 'debug');

=item C<$INFO> - Output generated through normal operation of the process

=cut

const our $INFO  => dualvar(3, 'info');

=item C<$WARN> - Non-fatal issues generated through abnormal operation of the process

=cut

const our $WARN  => dualvar(4, 'warn');

=item C<$ERROR> - The highest level, reserved for serious issues such as fatal errors

=cut

const our $ERROR => dualvar(5, 'error');

=back

=head1 EXPORTED CONSTANTS

Individual levels may be imported directly via their name:

  use Essentials::Log::Level qw($TRACE $INFO);

Alternatively, you can import all constants at once using the C<:constants> tag:

  use Essentials::Log qw(:constants);

=head1 EXPORTED FUNCTIONS

=over

=item C<from_string($name)>

Attempts to return the associated constant for the provided level C<$name>.

C<$name> is required, and must be a string, which will be lowercased before matching.

Will throw an L<Essentials::Exception> if an associated level cannot be found.

=cut

sub from_string {
    my $string = shift;

    throw "No string provided" unless $string;

    $string = lc $string;

    foreach my $name (@{ $EXPORT_TAGS{constants} }) {
        my $level = ${$Essentials::Log::Level::{substr($name, 1)}};
        return $level if $level eq $string;
    }

    throw "Unknown log level: $string";
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Log>

=back

=cut

1;
