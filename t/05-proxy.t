#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use AnyEvent::HTTP;
use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(fatal));

my $tls_ctx = { cert_file => 't/cert.pem' };
my $server  = Test::HTTP::AnyEvent::Server->new(
    https   => $tls_ctx,
);
my $cv = AE::cv;

for my $proto (qw(http https)) {
    $cv->begin;
    http_request
        GET     => qq($proto://ohhai/echo/head),
        proxy   => [ $server->address => $server->port ],
        tls_ctx => $tls_ctx,
        sub {
            my ($body, $hdr) = @_;
            like($body, qr{\bHost\s*:\s*ohhai\b}isx, q(fake host));
            ok($hdr->{q(content-type)} eq q(text/plain), q(Content-Type));
            ok($hdr->{connection} eq q(close), q(Connection));
            like($hdr->{server}, qr{^Test::HTTP::AnyEvent::Server/}x, q(User-Agent));

            $cv->end;
        };
}

$cv->wait;

done_testing(8);
