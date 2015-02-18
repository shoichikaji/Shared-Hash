package t::Util;
use strict;
use warnings;
use 5.010;
use Exporter 'import';
our @EXPORT = qw(do_fork);

sub do_fork (&) {
    my $cb = shift;
    my $pid = fork // die;
    return $pid if $pid;
    $cb->();
    exit;
}


1;
