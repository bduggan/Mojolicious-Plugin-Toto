=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

 use Mojolicious::Lite;

 get '/my/url/to/list/beers' => sub {
      shift->render_text("Here is a page for listing beers.");
 } => "beer/list";

 get '/beer/create' => sub {
    shift->render_text("Here is a page to create a beer.");
 } => "beer/create";

 plugin 'toto' =>
    menu => [
        beer    => { one  => [qw/view edit pictures notes/],
                     many => [qw/list create search browse/] },
        brewery => { one  => [qw/view edit directions beers info/],
                     many => [qw/phonelist mailing_list/] },
        pub     => { one  => [qw/view info comments hours/],
                     many => [qw/search map/] },
    ],
 ;

 app->start

 ./Beer daemon

=head1 DESCRIPTION

This plugin provides a navigational structure and a default set
of routes for a Mojolicious or Mojolicious::Lite app.

It extends the idea of BREAD or CRUD -- in a BREAD application,
browse and add are operations on aggregate (0 or many) objects, while
edit, add, and delete are operations on 1 object.

Toto groups all pages into two categories : either they act on one
object, or they act on 0 or many objects.

One set of tabs provides a way to change between types of objects.
Another row of tabs provides a way to change actions.

The actions displayed depend on context -- the type of object, and
whether or not an object is selected determine the list of actions
that are displayed.

The toto menu data structure is used to generate default routes of
the form controller/action, for each controller+action pair.
It is also used to generate the menu and tabs.

By loading the plugin after creating routes, any routes created
manually which use this naming convention will take precedence over
the default ones.

For Mojolicious (not lite) apps, methods in controller classes will
be used if they exist.

Because routes are created automatically, creating a page may be
done by just adding a file named templates/controller/action.html.ep.

Styling is done with twitter's bootstrap <http://twitter.github.com/bootstrap>.

=head1 SEE ALSO

http://www.beer.dotcloud.com

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Mojolicious::Plugin::Toto::Model;
use Cwd qw/abs_path/;

use strict;
use warnings;

our $VERSION = 0.08;

sub _render_static {
    my $c = shift;
    my $what = shift;
    $c->render_static($what);
}

sub register {
    my ($self, $app, $conf) = @_;

    my @menu = @{ $conf->{menu} || [] };
    my $prefix = $conf->{prefix} || '';
    my %menu = @menu;

    my $base = catdir(abs_path(dirname(__FILE__)), qw/Toto Assets/);
    my $default_path = catdir($base,'templates');
    push @{$app->renderer->paths}, catdir($base, 'templates');
    push @{$app->static->paths},   catdir($base, 'public');

    for my $controller (keys %menu) {

        my $first;
        for my $action (@{ $menu{$controller}{many} || []}) {
            # TODO skip existing routes
            $first ||= $action;
            $app->log->debug("Adding route for $prefix/$controller/$action");
            $app->routes->get(
                "$prefix/$controller/$action" => sub {
                    my $c = shift;
                    my @found = map { glob "$_/$controller/$action.*" } $c->app->renderer->paths;
                    return if @found;
                    $c->app->renderer->paths->[0] = $default_path;
                    $c->stash->{template}           = "plural";
                    $c->stash->{toto_prefix}        = $prefix;
                  } => {
                    controller => $controller,
                    action     => $action,
                    layout     => "toto"
                  } => "$controller/$action"
            );
        }
        my $first_action = $first;
        $app->routes->get(
            "$prefix/$controller" => sub {
                my $c = shift;
                $c->redirect_to("$prefix/$controller/$first_action");
              } => "$controller"
        );
        $first = undef;
        for my $action (@{ $menu{$controller}{one} || [] }) {
            # TODO skip existing routes
            $first ||= $action;
            $app->log->debug("Adding route for $prefix/$controller/$action/*key");
            $app->routes->get( "$prefix/$controller/$action/(*key)" => sub {
                    my $c = shift;
                    $c->app->log->debug("hi there");
                    $c->stash(instance => $c->model_class->new(key => $c->stash('key')));
                    my @found = map { glob "$_/$controller/$action.*" } $c->app->renderer->paths;
                    return if @found;
                    $c->stash->{template}           = "single";
                    $c->stash->{toto_prefix}        = $prefix;
                    $c->app->renderer->paths->[0] = $default_path;
                  } => {
                      controller => $controller,
                      action     => $action,
                      layout => "toto",
                  } => "$controller/$action"
            );
        }
        my $first_key = $first;
        $app->routes->get(
            "$prefix/$controller/default/(*key)" => sub {
                my $c = shift;
                my $key = $c->stash("key");
                $c->redirect_to("$controller/$first_key/$key");
              } => "$controller/default"
        );

    }
    my @controllers = grep !ref($_), @menu;
    my $first_controller = $controllers[0];
    $app->routes->get("$prefix/" => sub { shift->redirect_to($first_controller) } );

    for ($app) {
        $_->helper( toto_config => sub { $conf } );
        $_->helper( model_class => sub { $conf->{model_class} || "Mojolicious::Plugin::Toto::Model" });
        $_->helper( controllers => sub { @controllers } );
        $_->helper(
            actions => sub {
                my $c    = shift;
                my $for  = shift || $c->stash("controller") || die "no controller";
                my $mode = defined( $c->stash("key") ) ? "one" : "many";
                @{ $menu{$for}{$mode} || [] };
            }
        );
    }

    $app->hook(
        before_render => sub {
            my $c    = shift;
            my $args = shift;
            return if $args->{partial};
            return if $args->{no_toto} or $c->stash("no_toto");
            return unless $c->match && $c->match->endpoint;
            my $name = $c->match->endpoint->name;
            my ( $controller, $action ) = $name =~ m{^(.*)/(.*)$};
            return unless $controller && $action;
            $c->stash->{template_class} = "Toto";
            $c->stash->{layout}         = "toto";
            $c->stash->{action}         = $action;
            $c->stash->{controller}     = $controller;
            my $key = $c->stash("key") or return 1;
            $c->stash( instance => $c->model_class->new( key => $key ) );
        }
    );
    $self;
}

1;

__DATA__

@@ layouts/toto.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
<title><%= title %></title>
%= base_tag
%= stylesheet "bootstrap/css/bootstrap.min.css";
<style>
pre.toto_code {
    float:right;
    right:10%;
    padding:5px;
    border:1px grey dashed;
    font-family:monospace;
    position:absolute;
    }
</style>
</head>
<body>
<div class="container">
<div class="row">
<div class="span1">&nbsp;</div>
<div class="span11">
    <ul class="nav nav-tabs">
% for my $c (controllers) {
        <li <%== $c eq $controller ? q[ class="active"] : "" =%>>
            <%= link_to "$toto_prefix/$c" => begin =%><%= $c =%><%= end =%>
        </li>
% }
    </ul>
</div>
</div>
    <div class="tabbable tabs-left">
% if (stash 'key') {
%= include 'top_tabs_single';
% } else {
%= include 'top_tabs_plural';
% }
         <div class="tab-content" style='width:auto;'>
         <%= content =%>
         </div>
    </div>
</div>
</html>

