package Essentials::Test::Critic;

use v5.26;
use strictures 2;

# VERSION

use File::ShareDir qw(dist_file);
use Moo;
use Try::Tiny;

# ABSTRACT: Perlcritic test runner with a shared config file

=head1 SYNOPSIS

  use Essentials::Test::Critic;

  # Test using the default Essentials critic config
  my $critic = Essentials::Test::Critic->new;
  $critic->all_ok();

  # Test using a custom config file
  my $critic = Essentials::Test::Critic->new(
      file_path => '/path/to/perlcritic.conf',
  );
  $critic->all_ok();

=head1 DESCRIPTION

This module wraps L<Test::Perl::Config> with a custom configuration
file that is packaged along with this module.

=head1 ATTRIBUTES

=over

=item C<file_path>

The path to the perlcritic config file to use.

Defaults to C<share/perlcritic.conf>

=cut

has file_path => (
    is      => 'ro',
    default => sub {
        my $file_path;
        try {
            $file_path = dist_file('Essentials-Test', 'perlcritic.conf');
        }
        catch {
            $_ =~ /^(.+) at/;
            die "$1, is Essentials::Test installed?";
        };
        return $file_path;
    },
);

=back

=head1 METHODS

=over

=item C<all_ok(@args)>

Calls L<Test::Perl::Critic#all_critic_ok> with the arguments provided.

=cut

sub all_ok {
    my ($self, @args) = @_;

    require Test::Perl::Critic;

    Test::Perl::Critic->import(
        -profile => $self->file_path,
    );

    Test::Perl::Critic::all_critic_ok(@args);
}

=back

=head1 SEE ALSO

=over

=item L<Test::Perl::Critic>

=back

=cut

1;
