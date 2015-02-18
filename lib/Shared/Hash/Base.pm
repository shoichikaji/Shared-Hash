package Shared::Hash::Base;
use strict;
use warnings;
use 5.010;

sub read {
    my ($self, $socket, $length) = @_;
    my $rest = $length;
    my $buffer = "";
    while ($rest) {
        my $l = $socket->sysread(my $buf, $length);
        return unless defined $l;
        return if $l == 0; # EOF
        $buffer .= $buf;
        $rest -= $l;
    }
    return $buffer;
}

sub write {
    my ($self, $socket, @data) = @_;
    my $data = join "", @data;
    my $length = length $data;
    my $offset = 0;
    while ($offset < $length) {
        my $l = $socket->syswrite($data, $length - $offset, $offset);
        return unless defined $l;
        $offset += $l;
    }
    return 1;
}

sub next_length {
    my ($self, $socket) = @_;
    my $pack = $self->read($socket, 4) // return;
    unpack("I", $pack);
}

sub pack_length {
    my ($self, $data) = @_;
    pack("I", length $data);
}

1;
