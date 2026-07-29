# NAME

Essentials::DB - Modules for managing multiple DBIx::Class schemas under custom namespaces

# VERSION

version 0.1.1

# SYNOPSIS

Given the following SQL schema:

    CREATE TABLE `group` (
      `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` VARCHAR(64) NOT NULL,
      `description` VARCHAR(255) DEFAULT '',
      PRIMARY KEY (`id`)
    ) DEFAULT CHARSET=utf8mb4;

    CREATE TABLE `user` (
      `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` VARCHAR(64) NOT NULL,
      `email` VARCHAR(64) NOT NULL UNIQUE,
      `password_hash` CHAR(60) NOT NULL,
      PRIMARY KEY (`id`)
    ) DEFAULT CHARSET=utf8mb4;

    CREATE TABLE `user_group` (
      `user_id` INT UNSIGNED NOT NULL,
      `group_id` INT UNSIGNED NOT NULL,
      PRIMARY KEY (`user_id`, `group_id`),
      FOREIGN KEY (`user_id`)
        REFERENCES `user`(`id`)
        ON DELETE CASCADE,
      FOREIGN KEY (`group_id`)
        REFERENCES `group`(`id`)
        ON DELETE CASCADE
    ) DEFAULT CHARSET=utf8mb4;

Create some corresponding [DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSource) classes (or generate them using [dbicdump](https://metacpan.org/pod/dbicdump))...

_MyApp/DB/Result/Group.pm_

    package MyApp::DB::Result::Group;

    use base 'DBIx::Class::Core';

    __PACKAGE__->table('group');
    __PACKAGE__->add_columns(
      id   => {
        data_type         => 'integer',
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
      },
      name => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 0,
      },
      description => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 1,
        default_value => '',
      },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(
      'user_groups',
      'MyApp::DB::Result::UserGroup',
      {
        'foreign.group_id' => 'self.id',
      },
      {
        cascade_copy => 0,
        cascade_delete => 0,
      }
    );
    __PACKAGE__->many_to_many('users', 'user_groups', 'user');

    1;

_MyApp/DB/Result/User.pm_

    package MyApp::DB::Result::User;

    use base 'DBIx::Class::Core';

    __PACKAGE__->table('user');
    __PACKAGE__->add_columns(
      id   => {
        data_type         => 'integer',
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
      },
      name => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 0,
      },
      email => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 0,
      },
      password_hash => {
        data_type   => 'char',
        size        => 60,
        is_nullable => 0,
      },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->add_unique_constraint('email', ['email']);
    __PACKAGE__->has_many(
      'user_groups',
      'MyApp::DB::Result::UserGroup',
      {
        'foreign.user_id' => 'self.id',
      },
      {
        cascade_copy => 0,
        cascade_delete => 0,
      }
    );
    __PACKAGE__->many_to_many("groups", "user_groups", "group");

    1;

_MyApp/DB/Result/UserGroup.pm_

    package MyApp::DB::Result::UserGroup;

    use base 'DBIx::Class::Core';

    __PACKAGE__->table('user_group');
    __PACKAGE__->add_columns(
      user_id   => {
        data_type      => 'integer',
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
      },
      group_id   => {
        data_type      => 'integer',
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
      },
    );
    __PACKAGE__->set_primary_key('user_id', 'group_id');
    __PACKAGE__->belongs_to(
      'group',
      'MyApp::DB::Result::Group',
      {
        id => 'group_id',
      },
      {
        is_deferrable => 1,
        on_delete => 'CASCADE',
        on_update => 'RESTRICT',
      },
    );
    __PACKAGE__->belongs_to(
      'user',
      'MyApp::DB::Result::User',
      {
        id => 'user_id',
      },
      {
        is_deferrable => 1,
        on_delete => 'CASCADE',
        on_update => 'RESTRICT',
      },
    );

    1;

Now you can use this schema to interact with the database via [Essentials::DB](https://metacpan.org/pod/Essentials%3A%3ADB).

In _MyApp.pm_:

    package MyApp;

    use Essentials::DB;
    use Essentials::DB::Connection::Config;

    # Load a subclass of DBIx::Class::Schema under MyApp::DB,
    # or create one if it doesn't exist
    my $db = Essentials::DB->new(package => 'MyApp::DB');

    # Load your schema information
    $db->package->load_namespaces(...);

    # create a new connection
    my $conn = $db->connect(
        Essentials::DB::Connection::Config->new(
            driver   => 'mysql', # DBI driver name
            database => 'mydb',
            hostname => 'writer.mydb.com',
            username => 'example_rw',
            password => 'hunter2',
        )
    );

    # fetch all users
    my $all_users = $conn->resultset('User');
    # read the next row
    my $next_user = $all_users->next;
    # or slurp all rows into an array
    my @all_users = $all_users->all;

    # find a particular group
    my $group = $conn->resultset('Group')->find(
        { name => 'Admin' }
    );

    # find all users in that group
    my $admins = $group->users;

    # or do it all at once with a join
    $admins = $conn->resultset('User')->search(
        { 'group.name' => 'Admin' },
        { join => 'groups' },
    );

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

    my $pid = fork();

    # this is no longer safe!
    # take a look at Essentials::DB::Pool for a thread-safe alternative
    $conn->resultset(...);

    1;

See [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) for comprehensive documentation on the functionality
of the connections.

# DESCRIPTION

This module provides convenient methods for managing and connecting to
multiple [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) schemas within the same project.

# ATTRIBUTES

### package

The name of the [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) module to use for connections to
the database.

If this doesn't exist, one will be created for you.

This allows you to conveniently define multiple schemas within the
same application without needing to maintain the implementation of
each subclass yourself.

# METHODS

### `new(%args)`

Creates and returns a new instance of [Essentials::DB](https://metacpan.org/pod/Essentials%3A%3ADB).

The [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) package provided by the `package` attribute is loaded and
used for connections created by this instance. If the package doesn't exist, one is
created for you.

Before you can connect to the database, you will need to load your result and resultset
definitions using the static methods provided by [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema), such as 
[DBIx::Class::Schema#load\_namespaces](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema%23load_namespaces). These can be accessed via the `package` attribute:

    # creates the 'My::DB' module for you if it doesn't exist
    my $db = Essentials::DB->new(package => 'My::DB');

    # call a static method on 'My::DB' via its name
    $db->package->load_namespaces(...);

### `connect($config, $attr)`

Connects to the database via the config provided, and returns a
new instance of [Essentials::DB::Connection](https://metacpan.org/pod/Essentials%3A%3ADB%3A%3AConnection) under your custom namespace.

`$config` is an instance of [Essentials::DB::Connection::Config](https://metacpan.org/pod/Essentials%3A%3ADB%3A%3AConnection%3A%3AConfig).

    my $conn = $schema->connect(
        Essentials::DB::Connection::Config->new(...),
    );

`$attr` is an optional hashref containing overrides for the [DBI](https://metacpan.org/pod/DBI) connection
attributes, such as `AutoCommit` and `RaiseError`.

See [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) for comprehensive documentation on the functionality
of the connections.

# SEE ALSO

- [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass)
- [Essentials::DB::Pool](https://metacpan.org/pod/Essentials%3A%3ADB%3A%3APool)
- [Essentials::DB::Connection](https://metacpan.org/pod/Essentials%3A%3ADB%3A%3AConnection)

# AUTHOR

Oliver Youle <oliver@youle.io>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Oliver Youle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
