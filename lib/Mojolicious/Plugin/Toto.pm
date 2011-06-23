=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

 cat > ./Beer
 #!/usr/bin/env perl
 use Mojolicious::Lite;

 get '/my/url/to/list/beers' => sub {
      shift->render_text("Here is a page for listing beers.");
 } => "beer/list";

 get '/beer/create' => sub {
    shift->render_text("Here is a page to create a beer.");
 };

 plugin 'toto' =>
    menu => [
        beer    => { one  => [qw/view edit pictures notes/],
                     many => [qw/list create search browse/] },
        brewery => { one  => [qw/view edit directions beers info/],
                     many => [qw/phonelist mailing_list/] },
        pub     => { one  => [qw/view info comments hours/],
                     many => [qw/search map/] },
    ]
 ;

 app->start

 ./Beer daemon

=head1 DESCRIPTION

This plugin provides a navigational structure for a Mojolicious
or Mojolicious::Lite app.

It provides a menu for changing between types of objects, and it
provides rows of tabs which correspond to actions.

It extends on the idea of BREAD or CRUD -- in a BREAD application,
browse and add are operations on aggregate (0 or many) objects, while
edit, add, and delete are operations on 1 object.

Toto groups all pages into two categories : either they act on 1
object, or they act on 0 or many objects.

A rows of tabs is displayed which shows other actions.  The row
depends on the context -- the type of object, and whether or not
an object is selected.

A data structure is used to configure the navigational structure.
This data structure should describe the types of objects
as well as the possible actions.

For Mojolicious::Lite apps, routes whose names are of the form
"controller/action" will automatically be placed into the navigational
structure.  Note that each "controller" corresponds to one "object".

For Mojolicious (not lite) apps, methods in controller classes will
be used if they exist.

Styling is done (mostly) with jquery css.

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
            my $name = $c->match->endpoint->name;
            my ( $controller, $action ) = $name =~ m{^(.*)/(.*)$};
            $c->stash->{template_class} = "Toto";
            $c->stash->{layout}         = "toto";
            $c->stash->{action}         = $action;
            $c->stash->{controller}     = $controller;
            my $key = $c->stash("key") or return 1;
            $c->stash( instance => $c->model_class->new( key => $key ) );
        }
    );
}

1;

