# NAME

Essentials::Config - A library for managing config files in various common formats

# VERSION

version 0.1.0

# SYNOPSIS

    use Essentials::Config;

    my $config = Essentials::Config->new;

    # load data from a YAML file
    my $data = $config->read_file('/path/to/file.yaml');

    # make some transformations...
    $data->{example} = 'new value';

    # save the data as JSON
    #config->write_file('/path/to/file.json', $data);

# DESCRIPTION

This module provides methods for reading and writing to files of
various formats commonly used for application configuration.

The underlying driver is selected automatically based on the
extension of the file path provided.

Supported formats:

- CNF
- INI
- JSON
- XML
- YAML

# METHODS

- `read_file($file_path)`

    Reads the contents of the file at the path provided and returns
    the decoded contents as a hashref or arrayref (depending on the
    file contents).

    `$file_path` is a string containing the path of the file to read.

    The encoding of the file is determined automatically.

- `write_file($file_path, $data)`

    Writes the `$data` provided to a file at the provided `$file_path`,
    encoding the data based on the extension of the file provided.

    `$data` is an arrayref or hashref.

    `$file_path` is a string containing the path of the file to write to.

# AUTHOR

Oliver Youle <oliver@youle.io>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Oliver Youle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
