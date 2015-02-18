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
It uses unix domain socket.

## FEATURES

- easy to use
- support lock

        # this is atomic!
        $hash->lock(sub {
            my $hash = shift;
            my $i = $hash->get("foo");
            $i++;
            $hash->set(foo => $i);
        });

- hash may contain arbitrary perl data type

        $hash->set(foo => { hash => "ref" });
        $hash->set(bar => [1..10]);

## METHODS

- `$hash->get($key)`

    If `$hash` does not contain `$key`, then it returns `undef`

- `$hash->set($key, $value)`
- `$hash->lock($callback)`

    `$callback` will be executed with locked `$hash` as a arguemnt.

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
