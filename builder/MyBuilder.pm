package builder::MyBuilder;
use strict;
use warnings;

use parent 'Module::Build';

sub new {
    my $class = shift;
    unless (eval { require IO::Socket::UNIX }) {
        warn "Sorry, this module is only available on *nix OS.\n";
        exit;
    }
    $class->SUPER::new(@_);
}

1;
