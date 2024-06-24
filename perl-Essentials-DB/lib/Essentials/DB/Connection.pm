package Essentials::DB::Connection;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;
use Try::Tiny;

use Essentials::Exception qw(throw);

# ABSTRACT: A custom role for extending DBIx::Class connections under custom namespaces

=head1 SYNOPSIS

  # create a concrete implementation under a custom namespace
  {
      package MyApp::DB::Connection;

      use Moo;

      extends 'DBIx::Class::Schema';

      with 'Essentials::DB::Connection';

      1;
  }

  # load your schema config first
  MyApp::DB::Connection->load_namespaces(...);

  # connect to the database
  my $conn = MyApp::DB::Connection->connect(...);

  # create a new user and add them to a group in a transaction
  # throws an Essentials::Exception and rolls back on error
  $conn->txn(sub {
      # $conn is passed in as the first argument
      my $c = shift;
      my $new_user = $c->resultset('User')->create({
          name          => 'Alice Johnson',
          email         => 'alice.johnson@example.com',
          password_hash => '$2b$12$securehashedpassword...',
      });
      $new_user->add_to_groups({ name => 'Member' });
  });

=head1 DESCRIPTION

This package provides a Moo role for extending the functionality of
L<DBIx::Class::Schema> connections for use with L<Essentials::DB>.

It's unlikely that you'll want to implement this role directly, rather, see
L<Essentials::DB> for a convenient way of building connections under a custom
namespace.

For more information on querying the database, see L<DBIx::Class>.

=head1 METHODS

=head3 C<txn($coderef)>

Executes the provided C<$coderef> in a transaction.

The current connection will be passed in as the first parameter
to the coderef.

If an error occurs during the transaction, a roll-back will
be attempted and an L<Essentials::Exception> thrown.

See L<DBIx::Class::Schema#txn_do> for more information on
how the transaction is handled.

=cut

sub txn {
    my ($self, $coderef) = @_;

    my $wantarray = wantarray();

    my ($result, @result);
    try {
        if ($wantarray) {
            @result = $self->txn_do(sub {
                $coderef->($self);
            });
        }
        else {
            $result = $self->txn_do(sub {
                $coderef->($self);
            });
        }
    }
    catch {
        throw $_;
    };

    if ($wantarray) {
        return @result;
    }

    return $result;
}

1;
