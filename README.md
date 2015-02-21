# NAME

Shared::Hash - hash-like object which is shared between processes

# SYNOPSIS

    use Shared::Hash;

    my $hash = Shared::Hash->new;

    my $pid = fork // die;
    if ($pid == 0) {
        # child
        $hash->set(message => "from child!");
        exit;
    }

    sleep 1;
    print $hash->get("message"); # from child!

# DESCRIPTION

Shared::Hash is a hash-like object which is shared between processes.
It uses a file for IPC.

## FEATURES

- support lock

        $hash->lock(sub {
            # in this callback, your operations for $hash are atomic!
            my $i = $hash->get("foo");
            $i++;
            $hash->set(foo => $i);
        });

- hash may contain arbitrary perl data type

        $hash->set(foo => { hash => "ref" });
        $hash->set(bar => [1..10]);

## CONSTRUCTOR

### `my $hash = Shared::Hash->new(%option)`

Create a new Shared::Hash object. `%option` may be:

    path => "filepath"

The default path is a temp file.

## METHODS

### `my $value = $hash->get($key)`

Get the value for `$key`.
If `$hash` does not contain `$key`, then it returns `undef`.

### `$hash->set($key, $value)`

Set `$value` for `$key`.

### `my $hash_ref = $hash->as_hash`

Get a cloned hash reference.

### `my @keys = $hash->keys`

All keys of `$hash`.

### `my @values = $hash->values`

All values of `$hash`.

### `$hash->lock($callback)`

In `$callback`, your operation for `$hash` is atomic.

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
