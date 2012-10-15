#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use AnyEvent::HTTP;
use Scalar::Util qw(looks_like_number);
use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(fatal));

my $server = Test::HTTP::AnyEvent::Server->new;
my $cv = AE::cv;

$cv->begin;
http_request GET => $server->uri . q(echo/head), sub {
    my ($body, $hdr) = @_;

    like($body, qr{^GET\s+/echo/head\s+HTTP/1\.[12]\b}isx, q(echo/head));
    ok($hdr->{q(content-type)} eq q(text/plain), q(Content-Type));
    ok($hdr->{connection} eq q(close), q(Connection));
    like($hdr->{server}, qr{^Test::HTTP::AnyEvent::Server/}x, q(User-Agent));

    $cv->end;
};

$cv->begin;
my $body = q(key1=value1&key2=value2);
http_request POST => $server->uri . q(echo/body), body => $body, sub {
    ok($_[0] eq $body, q(echo/body));
    $cv->end;
};

$cv->begin;
http_request GET => $server->uri . q(repeat/123/qwerty), sub {
    like($_[0], qr{^(?:qwerty){123}$}x, q(repeat));
    $cv->end;
};

$cv->begin;
my $stamp = time;
http_request GET => $server->uri . q(delay/3), timeout => 5, sub {
    if ($_[0] =~ m{^issued\s+(.+)$}ix) {
        my $issued = AnyEvent::HTTP::parse_date($1);
        ok(looks_like_number($issued), q(parsed time string));
        ok($issued == $stamp, q(detected immediately));
        $issued = time - $issued;
        ok($issued >= 2, qq(delay $issued within lower range));
        ok($issued <= 4, qq(delay $issued within upper range));
    } else {
        fail(q(invalid date response));
    }
    $cv->end;
};

$cv->begin;
http_request GET => $server->uri . q(non-existent), sub {
    ok($_[1]->{Status} == 404, q(Not Found));
    $cv->end;
};

$cv->begin;
http_request HEAD => $server->uri, sub {
    ok($_[1]->{Status} == 400, q(Bad Request));
    $cv->end;
};

$cv->wait;

done_testing(12);
