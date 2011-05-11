#!perl

use Test::More qw/no_plan/;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'toto' => path => "/app",
  menu        => [
    beer => {
        many => [qw/search browse/],
        one  => [qw/picture ingredients pubs/],
    },
    pub => {
        many => [qw/map/],
        one  => [qw/info comments/],
    }
  ];

my $t = Test::Mojo->new();
$t->max_redirects(1);

$t->get_ok('/app')->status_is(200)->content_like(qr/welcome/i);

$t->get_ok('/app/beer')->status_is(200)->content_like(qr/search/i);
$t->get_ok('/app/pub')->status_is(200)->content_like(qr/map/i);

1;


