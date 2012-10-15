#!perl
use strict;
use utf8;
use warnings qw(all);

BEGIN {
    unless ($ENV{AB}) {
        require Test::More;
        Test::More::plan(skip_all => q(requires Apache HTTP server benchmarking tool));
    }
}

use Test::More;

use AnyEvent::Util;
use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(fatal));

my $server = Test::HTTP::AnyEvent::Server->new;

my $buf;
my $num = 1000;

$buf = '';
my $cv = run_cmd
    [qw[
        ab
        -c 10
        -n], $num, qw[
        -r
    ], $server->uri . q(echo/head)],
    q(<)    => q(/dev/null),
    q(>)    => \$buf,
    q(2>)   => q(/dev/null),
    close_all => 1;
$cv->recv;
like($buf, qr{\bComplete\s+requests:\s*${num}\b}isx, q(benchmark complete));
like($buf, qr{\bFailed\s+requests:\s*0\b}isx, q(benchmark failed));
like($buf, qr{\bWrite\s+errors:\s*0\b}isx, q(benchmark write errrors));

$buf = '';
$cv = run_cmd
    [qw[
        ab
        -c 100
        -n], $num, qw[
        -i
        -r
    ], $server->uri . q(echo/head)],
    q(<)    => q(/dev/null),
    q(>)    => \$buf,
    q(2>)   => q(/dev/null),
    close_all => 1;
$cv->recv;
unlike($buf, qr{\bFailed\s+requests:\s*0\b}isx, q(benchmark failed));

done_testing(4);
