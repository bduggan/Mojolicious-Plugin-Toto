=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

 cat > ./Beer
 #!/usr/bin/env perl
 use Mojolicious::Lite;

 plugin 'toto' =>
    path => "/toto",
    namespace => "Beer",
    menu => [
        beer    => { one  => [qw/view edit pictures notes/],
                     many => [qw/create search browse/] },
        brewery => { one  => [qw/view edit directions beers info/],
                     many => [qw/phonelist mailing_list/] },
        pub     => { one  => [qw/view info comments hours/],
                     many => [qw/search map/] },
 #  $controller (object) => { one => [ ..actions on one object ],
 #                          many => [ ..actions on 0 or many objects ]
    ]
 ;

 get '/my/url/to/search/for/beers' => sub {
      shift->render_text("Here is a page for searching for beers.");
 } => "beer/search";

 get '/beer/create' => sub {
    shift->render_text("Here is a page to create a beer.");
 };
 app->start

 ./Beer daemon

=head1 DESCRIPTION

This plugin provides a navigational structure for a Mojolicious
or Mojolicious::Lite app.

It provides a menu for changing between types of objects, and it
provides rows of tabs which correspond to actions.

The rows of tabs which are displayed may relate to a particular
selected object, or may relate to zero or many objects.

This may be thought of as an extension of CRUD or BREAD :
The actions "create", "add", "browse", "search" are examples
of actions which correspond to zero or many objects.

The actions "read", "edit", "update", "delete" are actions
which are for exactly one object.

A data structure is used to configure the navigational structure.
This data structure should describe the types of objects
as well as the possible actions.

For Mojolicious::Lite apps, routes whose names are of the form
"controller/action" will automatically be placed into the navigational
structure.  Note that each "controller" corresponds to one "object".

For Mojolicious apps, methods in controller classes will be used
if they exist.

In addition to the expected template location,

    templates/$controller/$action.html.ep

, toto will also look for a template in

    templates/$action.html.ep

as a default action for all controller classes.

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Toto;
use strict;
use warnings;

our $VERSION = 0.03;

our $mainRoutes;
sub _main_routes {
     my $c = shift;
     our $mainRoutes;
     $mainRoutes ||= { map { ( $_->name => 1 ) }
          grep { $_->name && $_->name =~ m[/] }
          @{ $c->main_app->routes->children || [] }
     };
     return $mainRoutes;
}

sub _toto_url {
     my ($c,$controller,$action,$key) = @_;
     if ( $controller && $action && _main_routes($c)->{"$controller/$action"} ) {
        $c->app->log->debug("found a route for $controller/$action");
        return $c->main_app->url_for( "$controller/$action",
            { controller => $controller, action => $action, key => $key } );
     }
     $c->app->log->debug("default route for $controller".($action ? "/$action" : ""));
     # url_for "plural" or "single" doesn't work for the first http
     # request for some reason (toto_path is excluded)
     my $url = $c->req->url->clone;
     $url->path->parts([$c->toto_path, $controller]);
     push @{ $url->path->parts }, $action if $action;
     push @{ $url->path->parts }, $key if $action && defined($key);
     return $url;
}

sub register {
    my ($self, $app, $conf) = @_;

    my $path  = $conf->{path}      || '/toto';
    my $namespace = $conf->{namespace} || $app->routes->namespace || "Toto";
    my @menu = @{ $conf->{menu} || [] };
    my %menu = @menu;

    $app->routes->route($path)->detour(app => Toto::app());
    Toto::app()->routes->namespace($namespace);
    Toto::app()->renderer->default_template_class("Toto");

    my @controllers = grep !ref($_), @menu;
    for ($app, Toto::app()) {
        $_->helper( main_app => sub { $app } );
        $_->helper( toto_url => \&_toto_url );
        $_->helper( toto_path   => sub { $path } );
        $_->helper( model_class => sub { $conf->{model_class} || "Toto::Model" });
        $_->helper( controllers => sub { @controllers } );
        $_->helper(
            actions => sub {
                my $c    = shift;
                my $for  = shift || $c->stash("controller");
                my $mode = defined( $c->stash("key") ) ? "one" : "many";
                @{ $menu{$for}{$mode} || [] };
            }
        );
    }

    $app->hook(before_render => sub {
            my $c = shift;
            my $name = $c->stash("template"); # another method for name?
            return unless $name && _main_routes($c)->{$name};
            my ($controller,$action) = $name =~ m{^(.*)/(.*)$};
            $c->app->log->info("found $action, $controller");
            $c->stash->{template_class} = "Toto";
            $c->stash->{layout} = "toto";
            $c->stash->{action} = $action;
            $c->stash->{controller} = $controller;
            my $key = $c->stash("key") or return;
            $c->stash(instance => $c->model_class->new(key => $key));
        });
}

1;

