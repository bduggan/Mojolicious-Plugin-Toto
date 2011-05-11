#!perl

use Test::More qw/no_plan/;
use Mojolicious::Lite;
use Test::Mojo;

get '/hello' => sub { shift->render_text('hello') };

my $t = Test::Mojo->new();

$t->get_ok('/hello')->status_is(200)->content_is('hello');

1;


