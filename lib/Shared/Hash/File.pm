package Shared::Hash::File;
use strict;
use warnings;
use Fcntl qw(:DEFAULT :flock);
use File::Temp qw(tempfile);
use Storable qw(nfreeze thaw);
use constant CHUNK_SIXE => 1024**2;

{
    package Shared::Hash::File::Guard;
    sub new { bless $_[1], $_[0] }
    sub DESTROY { $_[0]->() }
}

sub new {
    my ($class, %option) = @_;
    my $path = $option{path};
    if (!$path) {
        (undef, $path) = tempfile OPEN => 0;
    }
    my $self = bless { path => $path, initial_pid => $$ }, $class;
    $self->_reopen;
    $self->_spew(+{});
    $self;
}

sub _reopen {
    my $self = shift;
    delete $self->{fh}; # just delete, don't close!
    sysopen my $fh, $self->{path}, O_RDWR|O_CREAT or die "open $self->{path}: $!";
    $self->{fh} = $fh;
    $self->{owner_pid} = $$;
}

sub DESTROY {
    my $self = shift;
    return if $self->{initial_pid} != $$;
    unlink $self->{path};
}

sub fh {
    my $self = shift;
    if ($self->{owner_pid} != $$) {
        $self->_reopen;
    }
    $self->{fh};
}

sub _slurp {
    my $self = shift;
    my $fh = $self->fh;
    sysseek $fh, 0, 0;
    my $buffer = "";
    while (sysread $fh, my $buf, CHUNK_SIXE) {
        $buffer .= $buf;
    }
    thaw $buffer;
}

sub _spew {
    my ($self, $data) = @_;
    my $fh = $self->fh;
    sysseek $fh, 0, 0;
    truncate $fh, 0;
    syswrite $fh, nfreeze $data;
}

sub get {
    my ($self, $key) = @_;
    my $guard = $self->_lock(LOCK_SH);
    my $hash = $self->_slurp;
    $hash->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    my $guard = $self->_lock(LOCK_EX);
    my $hash = $self->_slurp;
    $hash->{$key} = $value;
    $self->_spew($hash);
}

sub lock :method {
    my ($self, $cb) = @_;
    my $guard = $self->_lock(LOCK_EX);
    local $self->{in_lock} = 1;
    $cb->($self);
}

sub _lock {
    my ($self, $kind) = @_;
    return if $self->{in_lock};
    my $fh = $self->fh;
    flock $fh, $kind or die "flock $self->{path}: $!";
    Shared::Hash::File::Guard->new(sub { flock $fh, LOCK_UN });
}

1;
