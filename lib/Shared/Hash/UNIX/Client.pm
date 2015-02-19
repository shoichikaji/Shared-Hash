package Shared::Hash::UNIX::Client;
use strict;
use warnings;
use parent 'Shared::Hash::UNIX::Base';
use IO::Socket::UNIX;
use Storable qw(nfreeze thaw);
use Carp 'confess';

sub new {
    my ($class, $path) = @_;
    bless { path => $path }, $class;
}

sub _socket {
    my $self = shift;
    if ($self->{lock_socket}) {
        return $self->{lock_socket};
    }
    IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $self->{path},
    ) or confess "failed to connet server path=$self->{path}, errno=$!";
}

sub _close {
    my ($self, $socket) = @_;
    return if $self->{lock_socket};
    $socket->close;
    undef $socket;
}

sub ping {
    my $self = shift;
    local $@;
    eval { $self->_socket; 1 } ? 1 : 0;
}

sub get {
    my ($self, $key) = @_;
    my $socket = $self->_socket;
    $self->write(
        $socket,
        $self->pack_length("get"), "get",
        $self->pack_length("$key"), "$key",
    );
    my $length = $self->next_length($socket);
    my $stored = $self->read($socket, $length);
    $self->_close($socket);
    thaw($stored)->[0];
}

sub set {
    my ($self, $key, $value) = @_;
    my $socket = $self->_socket;
    my $stored = nfreeze( [$value] );
    $self->write(
        $socket,
        $self->pack_length("set"), "set",
        $self->pack_length($key), $key,
        $self->pack_length($stored), $stored,
    );
    $self->_close($socket);
}

sub lock :method {
    my ($self, $cb) = @_;
    my $socket = $self->_socket;
    $self->write(
        $socket,
        $self->pack_length("lock"), "lock",
    );
    {
        local $self->{lock_socket} = $socket;
        $cb->($self);
    }
    $self->_close($socket);
}

sub keys :method {
    # TODO
}

sub values :method {
    # TODO
}

1;
