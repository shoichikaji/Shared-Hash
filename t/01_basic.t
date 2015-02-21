use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use Shared::Hash;
use Time::HiRes ();

subtest "basic" => sub {
    my $hash = Shared::Hash->new;
    $hash->set(foo => 1);
    $hash->set(bar => [1]);
    $hash->set(baz => {hello => 1});
    # note: key MUST NOT a perl string...
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
};

done_testing;
