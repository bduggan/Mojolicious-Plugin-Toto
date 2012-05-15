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

 get '/pub/view' => { controller => 'Pub', action => 'view' } => 'pub/view';

 plugin 'toto' =>
    menu => [
        beer    => { one  => [qw/view edit pictures notes/],
                     many => [qw/list create search browse/] },
        brewery => { one  => [qw/view edit directions beers info/],
                     many => [qw/phonelist mailing_list/] },
        pub     => { one  => [qw/view info comments hours/],
                     many => [qw/search map/] },

      # object  => { one => ....tabs....
      #             many => ...more tabs...

    ],
 ;

 app->start

 ./Beer daemon

=head1 DESCRIPTION

This plugin provides a navigational structure and a default set
of routes for a Mojolicious or Mojolicious::Lite app.

It extends the idea of BREAD or CRUD -- in a BREAD application,
browse and add are operations on zero or many objects, while
edit, add, and delete are operations on one object.

Toto groups all pages into these two categories : either they act on
zero or many objects, or they act on one object.

One set of tabs provides a way to change between types of objects.
Another set of tabs is specific to the type of object selected.

The second set of tabs varies depending on whether or not
an object (instance) has been selected.

=head1 HOW DOES IT WORK

After loading the toto plugin, the default layout is set to 'toto'.
The name of the each route is expected to be of the form <object>/<tab>.
where <object> refers to an object in the menu structure, and <tab>
is a tab for that object.

Defaults routes are generated for every combination of object + associated tab.

Templates in the directory templates/<object>/<tab>.html.ep will be used when
they exist.

The stash values "object" and "tab" are set for each auto-generated route.
Also "noun" is set as an alias to "object".

Styling is done with twitter's bootstrap <http://twitter.github.com/bootstrap>,
and a version of bootstrap is included in this distribution.

If a route should be outside of the toto framework, just set the layout, e.g.

    get '/no/toto' => { layout => 'default' } => ...

To route to another controller

    get '/some/route' => { controller => "Foo", action => "bar" } ...

=head1 TODO

Document these helpers, which are added automatically :

toto_config, model_class, objects, current_object, current_tab, current_instance


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

our $VERSION = 0.10;

sub _render_static {
    my $c = shift;
    my $what = shift;
    $c->render_static($what);
}

sub _cando {
    my ($namespace,$controller,$action) = @_;
    my $package = join '::', ( $namespace || () ), b($controller)->camelize;
    return $package->can($action) ? 1 : 0;
}

sub _to_noun {
    my $word = shift;
    $word =~ s/_/ /g;
    $word;
}

sub _add_sidenav {
    my $self = shift;
    my $app = shift;
    my ($prefix, $nav_item, $object, $tab) = @_;
    die "no tab for $object" unless $tab;
    die "no nav item" unless $nav_item;

    my @found_template = map { glob "$_/$object.*" } @{ $app->renderer->paths };
    my $found_controller = _cando($app->routes->namespace,$object,$tab);
    $app->log->debug("Adding sidenav route for $prefix/$object/$tab ($nav_item)");
    my $r = $app->routes->under(
        "$prefix/$object/$tab" => sub {
            my $c = shift;
            $c->stash(template => ( @found_template ? $tab : "plural" ));
            $c->stash(object     => $object);
            $c->stash(noun       => $object);
            $c->stash(tab        => $tab);
            $c->stash(nav_item   => $nav_item);
          })->any;
    $r = $r->to("$object#$tab") if $found_controller;
    $r->name("$object/$tab");
}

sub _add_tab {
    my $self = shift;
    my $app = shift;
    my ($prefix, $nav_item, $object, $tab) = @_;
    my @found_object_template = map { glob "$_/$object/$tab.*" } @{ $app->renderer->paths };
    my @found_template = map { glob "$_/$tab.*" } @{ $app->renderer->paths };
    my $found_controller = _cando($app->routes->namespace,$object,$tab);
    $app->log->debug("Adding route for $prefix/$object/$tab/*key");
    $app->log->debug("Found controller class for $object/$tab/key") if $found_controller;
    $app->log->debug("Found template for $object/$tab/key") if @found_template || @found_object_template;
    my $r = $app->routes->under("$prefix/$object/$tab/(*key)"  =>
            sub {
                my $c = shift;
                $c->stash(object => $object);
                $c->stash(noun => _to_noun($object));
                $c->stash(tab => $tab);
                my $key = lc $c->stash('key');
                my @found_instance_template = map { glob "$_/$object/$key/$tab.*" } @{ $app->renderer->paths };
                $c->stash(
                    template => (
                          0 + @found_instance_template ? "$object/$key/$tab"
                        : 0 + @found_object_template ? "$object/$tab"
                        : 0 + @found_template        ? $tab
                        : "single"
                    )
                );
                my $instance = $c->current_instance;
                $c->stash( instance => $instance );
                $c->stash( nav_item => $nav_item );
                $c->stash( $object  => $instance );
                1;
              }
            )->any;
      $r = $r->to("$object#$tab") if $found_controller;
      $r->name("$object/$tab");
}

sub _from_menu {
    die "TODO";
    # return $nav, $sidenav, $tabs
}

sub register {
    my ($self, $app, $conf) = @_;
    $app->log->debug("registering plugin");

    my ($nav,$sidenav,$tabs) = @$conf{qw/nav sidenav tabs/};

    my $prefix = $conf->{prefix} || '';

    my $base = catdir(abs_path(dirname(__FILE__)), qw/Toto Assets/);
    my $default_path = catdir($base,'templates');
    push @{$app->renderer->paths}, catdir($base, 'templates');
    push @{$app->static->paths},   catdir($base, 'public');
    $app->defaults(layout => "toto", toto_prefix => $prefix);

    $app->log->debug("Adding routes");
    die "no nav routes" unless $conf->{nav};
    for my $nav_item ( @{ $conf->{nav} } ) {
        $app->log->debug("Adding routes for $nav_item");
        my $first;
        die "no sidenav for $nav_item" unless $conf->{sidenav}{$nav_item};
        for my $subnav_item ( @{ $conf->{sidenav}{$nav_item} } ) {
            $app->log->debug("routes for $subnav_item");
            my ( $object, $action ) = split '/', $subnav_item;
            if ($action) {
                $first ||= $subnav_item;
                $self->_add_sidenav($app,$prefix,$nav_item,$object,$action);
            } else {
                my $first_tab;
                die "no tabs for $subnav_item" unless $conf->{tabs}{$subnav_item};
                for my $tab (@{ $conf->{tabs}{$subnav_item} }) {
                    $first_tab ||= $tab;
                    $self->_add_tab($app,$prefix,$nav_item,$object,$tab);
                }
                $app->log->debug("Will redirect $prefix/$object/default/key to $object/$first_tab/\$key");
                $app->routes->get("$prefix/$object/default/*key" => sub {
                    my $c = shift;
                    my $key = $c->stash("key");
                    $c->redirect_to("$object/$first_tab/$key");
                    } => "$object/default ");
            }
        }
        $app->routes->get(
            $nav_item => sub {
                my $c = shift;
                $c->redirect_to($first);
            } => $nav_item );
    }

    my $first_object = $conf->{nav}[0];
    $app->routes->get("$prefix/" => sub { shift->redirect_to($first_object) } );

    for ($app) {
        $_->helper( toto_config => sub { $conf } );
        $_->helper( model_class => sub {
                my $c = shift;
                if (my $ns = $conf->{model_namespace}) {
                    return join '::', $ns, b($c->current_object)->camelize;
                }
                $conf->{model_class} || "Mojolicious::Plugin::Toto::Model"
             }
         );
        $_->helper(
            tabs => sub {
                my $c    = shift;
                my $for  = shift || $c->current_object or return;
                @{ $conf->{tabs}{$for} || [] };
            }
        );
        $_->helper( current_object => sub {
                my $c = shift;
                $c->stash('object') || [ split '\/', $c->current_route ]->[0]
            } );
        $_->helper( current_tab => sub {
                my $c = shift;
                $c->stash('tab') || [ split '\/', $c->current_route ]->[1]
            } );
        $_->helper( current_instance => sub {
                my $c = shift;
                my $key = $c->stash("key") || [ split '\/', $c->current_route ]->[2];
                return $c->model_class->new(key => $key);
            } );
        $_->helper( printable => sub {
                my $c = shift;
                my $what = shift;
                $what =~ s/_/ /g;
                $what } );
    }

    $self;
}

1;
