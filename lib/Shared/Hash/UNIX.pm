package Shared::Hash::UNIX;
use 5.010;
use strict;
use warnings;
use File::Temp 'tempfile';
use Time::HiRes ();
use Shared::Hash::UNIX::Client;
use Shared::Hash::UNIX::Server;

our $VERSION = "0.01";
my $ENV_KEY = "PERL_SHARED_HASH_PATH";

sub new {
    my ($class, %option) = @_;
    my ($server_pid, $path) = $class->_exec_server($option{path});
    my $client = Shared::Hash::UNIX::Client->new($path);
    $ENV{$ENV_KEY} = $path;
    my $self = bless {
        path => $path,
        server_pid => $server_pid,
        owner_pid => $$,
        client => $client,
    }, $class;

    for (1..10) {
        if ($client->ping) {
            return $self;
        } else {
            Time::HiRes::sleep(0.002);
        }
    }
    die "Failed to connect server";
}

sub path { shift->{path} }

sub _exec_server {
    my ($class, $path) = @_;
    if (!$path) {
        (undef, $path) = tempfile(SUFFIX => ".sock", OPEN => 0);
    }
    unlink $path;

    my $pid = fork // die "failed to fork: $!";
    return ($pid, $path) if $pid;

    my $server = Shared::Hash::UNIX::Server->new($path);
    $server->accept_loop;
    exit;
}

sub _shutdown_server {
    my $self = shift;
    my $pid = $self->{server_pid};
    kill TERM => $pid;
    kill KILL => $pid;
    waitpid $pid, 0;
    unlink $self->{path};
}

sub DESTROY {
    my $self = shift;
    return if $self->{owner_pid} != $$;
    $self->_shutdown_server;
}

sub get {
    my ($self, $key) = @_;
    $self->{client}->get($key);
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{client}->set($key, $value);
}

sub lock {
    my ($self, $cb) = @_;
    $self->{client}->lock($cb);
}

1;
__END__

=encoding utf-8

=head1 NAME

Shared::Hash::UNIX - hash-like object which is shared between processes

=head1 SYNOPSIS

    use Shared::Hash::UNIX;

    my $hash = Shared::Hash::UNIX->new;

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
It uses unix domain socket.

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

