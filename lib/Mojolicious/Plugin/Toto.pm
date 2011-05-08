=head1 NAME

Mojolicious::Plugin::Toto - the toto interface paradigm under mojolicious

=head1 DESCRIPTION

package Mojolicious::Plugin::Toto;

=cut

package Mojolicious::Plugin::Toto;
use File::Basename qw/basename/;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;

sub register {
    my $self = shift;
    my $app = shift;
    my $location = (!ref $_[0] ? shift : "/toto");
    my $conf = shift;
    my %conf = @$conf;
    $app->routes->route($location)->detour(app => Toto::app());

    my @nouns = grep !ref($_), @$conf;
    for ($app, Toto::app()) {
        $_->helper( toto_config => sub { @$conf } );
        $_->helper( nouns       => sub { @nouns } );
        $_->helper( many        => sub { @{ $conf{ $_[1] }{many} } } );
        $_->helper( one         => sub { @{ $conf{ $_[1] }{one} } } );
    }
}

package Toto::Controller;
use Mojo::Base 'Mojolicious::Controller';

sub default {
    my $c = shift;
    $c->render(template => "plural");
}

package Toto;
use Mojolicious::Lite;
use Mojo::ByteStream qw/b/;

get '/' => { layout => "menu" } => 'toto';

get '/:controller/:action' => {
    action    => "default",
    namespace => "Toto::Controller",
    layout    => "menu_plurals"
  } => sub {
    my $c = shift;
    my ( $action, $controller ) = ( $c->stash("action"), $c->stash("controller") );
    if ($c->stash("action") eq 'default') {
        my $first = [ $c->many($controller) ]->[0];
        return $c->redirect_to( "plural" => action => $first, controller => $controller )
    }
    my $class = join '::', $c->stash("namespace"), b($controller)->camelize;
    $c->render(class => $class, template => "plural") unless $class->can($action);
  } => 'plural';

get '/:controller/:action/(*key)' => {
    action => "default",
    namespace => "Toto::Controller",
    layout => "menu_single"
} => sub {
    my $c = shift;
    my ( $action, $controller, $key ) =
      ( $c->stash("action"), $c->stash("controller"), $c->stash("key") );
    if ($c->stash("action") eq 'default') {
        my $first = [ $c->one($controller) ]->[0];
        return $c->redirect_to( "single" => action => $first, controller => $controller, key => $key )
    }
    my $class = join '::', $c->stash("namespace"), b($controller)->camelize;
    $c->render(class => $class, template => "single") unless $class->can($action);
} => 'single';

1;
__DATA__
@@ layouts/menu.html.ep
<!doctype html><html>
<head><title><%= title %></title></head>
<body>
%= link_to 'Toto' => 'toto';
% for my $noun (nouns) {
%= link_to url_for("plural", { controller => $noun }) => begin
%= $noun
%= end
% }
<div>
%= content "second_header";
%= content
</div>
</body>
</html>

@@ layouts/menu_plurals.html.ep
% layout 'menu';
%= content second_header => begin
<div>
% for my $action (many($controller)) {
%= link_to url_for("plural", { controller => $controller, action => $action }) => begin
%= $action
%= end
% }
</div>
% end

@@ layouts/menu_single.html.ep
% layout 'menu';
%= content second_header => begin
<div>
% for my $action (one($controller)) {
%= link_to url_for("single", { controller => $controller, action => $action, key => $key }) => begin
%= $action
%= end
% }
</div>
% end

@@ single.html.ep
This is the page for <%= $action %> for
<%= $controller %> <%= $key %>.

@@ plural.html.ep
your page to <%= $action %> <%= $controller %>s goes here<br>
(add <%= $class %>::<%= $action %>)<br>
<hr>
% for (1..10) {
%= link_to 'single', { controller => $controller, key => $_ } => begin
<%= $controller %> <%= $_ %><br>
%= end
% }
<hr>

@@ toto.html.ep
welcome to toto
