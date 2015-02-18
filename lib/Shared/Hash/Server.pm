package Shared::Hash::Server;
use strict;
use warnings;
use parent 'Shared::Hash::Base';
use IO::Socket::UNIX;
use Storable qw(nfreeze thaw);
use Carp 'confess';

my $UNDEF = nfreeze([undef]);

sub new {
    my ($class, $path) = @_;
    bless { HASH => +{}, path => $path }, $class;
}

sub DESTROY {
    my $self = shift;
    unlink $self->{path};
}

sub accept_loop {
    my $self = shift;

    my $socket = IO::Socket::UNIX->new(
        Listen => 10,
        Local => $self->{path},
        Type => SOCK_STREAM,
    ) or confess "failed to create socket path=$self->{path}, errno=$!";

    local $SIG{PIPE} = 'IGNORE';
    while (my $client = $socket->accept) {
        $self->handle_request($client);
        $client->close;
    }
}

my %handle = (
    get => '_handle_get',
    set => '_handle_set',
    lock => '_handle_lock',
);

sub handle_request {
    my ($self, $client, $length) = @_;
    $length ||= $self->next_length($client) or return;
    my $operation = $self->read($client, $length);
    if (my $method = $handle{$operation}) {
        $self->$method($client) or return;
    } else {
        warn "unknown $operation";
    }
}

sub _handle_get {
    my ($self, $client) = @_;
    my $length = $self->next_length($client) // return;
    my $key = $self->read($client, $length) // return;
    my $value = exists $self->{HASH}{$key} ? $self->{HASH}{$key} : $UNDEF;
    $self->write( $client, $self->pack_length($value), $value ) // return;
    return 1;
}

sub _handle_set {
    my ($self, $client) = @_;
    my $length;
    $length = $self->next_length($client) // return;
    my $key = $self->read($client, $length) // return;
    $length = $self->next_length($client) // return;
    my $value = $self->read($client, $length) // return;
    $self->{HASH}{$key} = $value;
    return 1;
}

sub _handle_lock {
    my ($self, $client) = @_;
    while (my $length = $self->next_length($client)) {
        $self->handle_request($client, $length);
    }
}

1;
