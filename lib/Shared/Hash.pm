package Shared::Hash;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.01";

sub new {
    my ($class, %option) = @_;
    my $driver = delete $option{driver} || "File";
    my $klass = "Shared::Hash::$driver";
    eval "require $klass;" or die $@;
    $klass->new(%option);
}

1;
__END__

=encoding utf-8

=head1 NAME

Shared::Hash - hash-like object which is shared between processes

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Shared::Hash is a hash-like object which is shared between processes.
It uses a file or a unix domain socket.

=head2 FEATURES

=over 4

=item easy to use

=item support lock

    # this is atomic!
    $hash->lock(sub {
        my $hash = shift;
        my $i = $hash->get("foo");
        $i++;
        $hash->set(foo => $i);
    });

=item hash may contain arbitrary perl data type

    $hash->set(foo => { hash => "ref" });
    $hash->set(bar => [1..10]);

=back

=head2 CONSTRUCTOR

=over 4

=item C<< my $hash = Shared::Hash->new(%option) >>

Create a new Shared::Hash objcect. C<%option> may be:

    driver => "File" or "UNIX"
    path   => "filepath" or "unixdomain.sock"

Default driver is File, and path is a tempfile.

=back

=head2 METHODS

=over 4

=item C<< $hash->get($key) >>

If C<$hash> does not contain C<$key>, then it returns C<undef>

=item C<< $hash->set($key, $value) >>

=item C<< $hash->lock($callback) >>

C<$callback> will be executed with locked C<$hash> as a arguemnt.

=back

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

