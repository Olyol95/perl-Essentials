package Essentials::Script::Service;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;

use Essentials::Exception qw(throw);

with 'Essentials::Script';

# ABSTRACT: A Moo role for wrapping services as modules

=head1 SYNOPSIS

In C<My/Service.pm>

  package My::Service;

  use Moo;

  with 'Essentials::Script::Service';

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

  # implement your service logic
  sub run {
      # do something, like processing a job from a queue
  }

  1;

In C<my-script.pl>

  #!/usr/bin/env perl

  use My::Service;
  use Essentials::Script::Heartbeat::Systemd;

  my $service = My::Service->new_with_opts(
      example_string => 'example-string=s',
      example_int    => 'baz=i',
      example_array  => 'array-item=s@',
      example_bool   => 'bool',
  )
  # Notify systemd on a successful run
  ->with_heartbeat(
      Essentials::Script::Heartbeat::Systemd->new
  )
  # Wait at least 5 seconds between runs
  ->with_min_interval(5);

  # start the service (blocking)
  $service->start;

  # stop the service
  $service->stop;

  # check whether the service is running
  if ($service->running) { ... }

=head1 DESCRIPTION

This package provides a L<Moo::Role> for implementing robust backend services.

In addition to the functionality detailed below, this role provides all of
the benefits of L<Essentials::Script>, including a convenient interface for
populating object attributes from command-line parameters as well as heartbeat
handlers for implementing service health checks.

=head1 ATTRIBUTES

=over

=item C<running>

A boolean that indicates whether or not the service is running.

=cut

has running => (
    is      => 'rw',
    default => 0,
);

=item C<min_interval>

The minimum time, in seconds, to wait between invocations of the C<run> method.

Defaults to 0, i.e. no wait.

=cut

has min_interval => (
    is      => 'rwp',
    default => 0,
);

=back

=head1 REQUIRED METHODS

The following methods require implementation in order to compose the role.

=over

=item C<run>

This method should contain all of the logic that you wish to execute on
each iteration of the service.

It will be invoked repeatedly once C<start> has been called, until
C<stop> is called.

The heartbeat handler will be notified after every call to this method.

=back

=head1 METHODS

=over

=item C<with_min_interval($seconds)>

Sets the the C<min_interval> attribute to the value provided.

Returns an instance of the object composing this role, for use
in a chained builder pattern:

  my $obj = Implements::Role->some_static_builder(
      ...
  )
  ->with_min_interval(5);

=cut

sub with_min_interval {
    my ($self, $seconds) = @_;

    $self->_set_min_interval($seconds);

    return $self;
}

sub BUILD {
    my $self = shift;

    foreach my $signal (qw(HUP TERM INT)) {
        local $SIG{$signal} = sub {
            $self->_interrupt($signal);
        };
    }
}

=item C<start>

Starts the service.

This call will block until C<stop> is called.

=cut

sub start {
    my $self = shift;

    $self->running(1);

    while ($self->running) {
        my $start_time = time();
        $self->run;
        $self->_sleep($start_time);
    }
}

=item C<stop>

Stops the service.

The current iteration will be allowed to finish gracefully.

=cut

sub stop {
    my $self = shift;

    $self->running(0);
}

sub _sleep {
    my ($self, $start_time) = @_;

    unless ($self->min_interval) {
        return;
    }

    my $time_taken = time() - $start_time;

    unless ($time_taken < $self->min_interval) {
        return;
    }

    my $sleep_time = $self->min_interval - $time_taken;
    $self->log->debug("Sleeping", {
        seconds => $sleep_time,
    });
    sleep $sleep_time;
}

sub _interrupt {
    my ($self, $signal) = @_;

    $self->log->info("Received signal", {
        signal => $signal,
    });

    $self->stop();
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script>

=item L<Essentials::Script::Heartbeat>

=back

=cut

1;
