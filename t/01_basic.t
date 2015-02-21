use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use Shared::Hash;
use Time::HiRes ();
use File::Temp 'tempfile';

my @must_removed;

subtest "basic" => sub {
    my $hash = Shared::Hash->new;
    $hash->set(foo => 1);
    $hash->set(bar => [1]);
    $hash->set(baz => {hello => 1});
    $hash->set("あ" => "い");
    is $hash->get("foo"), 1;
    is_deeply $hash->get("bar"), [1];
    is_deeply $hash->get("baz"), {hello => 1};
    is $hash->get("あ"), "い";
    is $hash->get("NO"), undef;

    is_deeply [ sort $hash->keys ], [qw( bar baz foo あ )];
    is scalar($hash->values), 4;
    is_deeply $hash->as_hash, {
        foo => 1, bar => [1], baz => {hello => 1}, "あ" => "い",
    };
    push @must_removed, $hash->path;
};

subtest "fork" => sub {
    my $hash = Shared::Hash->new;
    my $pid = do_fork {
        $hash->set(foo => 1);
        $hash->set(bar => [1]);
        $hash->set(baz => {hello => 1});
        $hash->set(hoge => "い");
    };
    waitpid $pid, 0;
    is $hash->get("foo"), 1;
    is_deeply $hash->get("bar"), [1];
    is_deeply $hash->get("baz"), {hello => 1};
    is $hash->get("hoge"), "い";
    is $hash->get("NO"), undef;
    push @must_removed, $hash->path;
};

subtest "lock" => sub {
    my $hash = Shared::Hash->new;
    $hash->set(foo => 0);
    my $pid = do_fork {
        $hash->lock(sub {
            $hash->set(foo => "lock");
            sleep 1;
            $hash->set(foo => 0);
        });
    };
    Time::HiRes::sleep(0.3);
    is $hash->get("foo"), 0 for 1..10;
    waitpid $pid, 0;
    push @must_removed, $hash->path;
};

subtest path => sub {
    (undef, my $tempfile) = tempfile(OPEN => 0);
    {
        my $hash = Shared::Hash->new( path => $tempfile );
        $hash->set( hello => "world" );
    }
    {
        my $hash = Shared::Hash->new( path => $tempfile );
        is $hash->get("hello"), "world";
    }
    ok -f $tempfile;
    unlink $tempfile;
};

for my $path (@must_removed) {
    ok !-e $path, "$path must be removed";
}

done_testing;
