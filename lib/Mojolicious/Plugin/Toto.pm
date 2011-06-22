=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

 cat > ./Beer
 #!/usr/bin/env perl
 use Mojolicious::Lite;

 plugin 'toto' =>
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

sub register {
    my ($self, $app, $conf) = @_;

    my @menu = @{ $conf->{menu} || [] };
    my %menu = @menu;

    $app->routes->get('/jq.css')->to("Toto");
    $app->routes->get('/toto.css')->to("Toto");
    $app->routes->get('/images/:which.png')->to("Toto"); # TODO subdir

    for my $controller (keys %menu) {

        my $first;
        for my $action (@{ $menu{$controller}{many} || []}) {
            # TODO skip existing routes
            $first ||= $action;
            $app->log->debug("Adding route for $controller/$action");
            $app->routes->get(
                "/$controller/$action" => sub {
                    my $c = shift;
                    $c->stash->{template}       = "plural";
                    $c->stash->{template_class} = 'Toto';
                  } => {
                    controller => $controller,
                    action     => $action,
                    layout     => "toto"
                  } => "$controller/$action"
            );
        }
        my $first_action = $first;
        $app->routes->get(
            "/$controller" => sub {
                shift->redirect_to("$controller/$first_action");
              } => "$controller"
        );
        $first = undef;
        for my $action (@{ $menu{$controller}{one} || [] }) {
            # TODO skip existing routes
            $first ||= $action;
            $app->routes->get(
                "/$controller/$action/(*key)" => sub {
                    my $c = shift;
                    $c->stash->{template}       = "single";
                    $c->stash->{template_class} = 'Toto';
                    $c->stash(instance => $c->model_class->new(key => $c->stash('key')));
                  } => {
                      controller => $controller,
                      action     => $action,
                      layout => "toto",
                  } => "$controller/$action"
            );
        }
        my $first_key = $first;
        $app->routes->get(
            "/$controller/default/(*key)" => sub {
                my $c = shift;
                my $key = $c->stash("key");
                $c->redirect_to("$controller/$first_key/$key");
              } => "$controller/default"
        );

    }


    my @controllers = grep !ref($_), @menu;
    for ($app, Toto::app()) {
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

    #$app->hook(before_render => sub {
    #        my $c = shift;
    #        my $name = $c->stash("template"); # another method for name?
    #        return unless $name && _main_routes($c)->{$name};
    #        my ($controller,$action) = $name =~ m{^(.*)/(.*)$};
    #        $c->app->log->info("found $action, $controller");
    #        $c->stash->{template_class} = "Toto";
    #        $c->stash->{layout} = "toto";
    #        $c->stash->{action} = $action;
    #        $c->stash->{controller} = $controller;
    #        my $key = $c->stash("key") or return;
    #        $c->stash(instance => $c->model_class->new(key => $key));
    #    });
}

1;

