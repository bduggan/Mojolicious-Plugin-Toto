=head1 NAME

Mojolicious::Plugin::Toto - the toto navigational structure

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
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
<title><%= title %></title>
%= stylesheet '/toto.css';
</head>
<body>
<div id="left-sidebar">
%= link_to 'Toto' => 'toto';
<ul class="left-menu">
% for my $noun (nouns) {
<li <%== $noun eq $controller ? q[ class="selected"] : "" =%>>
%= link_to url_for("plural", { controller => $noun }) => begin
<%= $noun =%>s
%= end
% }
</div>
</ul>
<div id="content">
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
<hr>
your page to <%= $action %> <%= $controller %>s goes here<br>
(add <%= $class %>::<%= $action %>)<br>
% for (1..10) {
%= link_to 'single', { controller => $controller, key => $_ } => begin
<%= $controller %> <%= $_ %><br>
%= end
% }
<hr>

@@ toto.html.ep
welcome to toto

@@ toto.css
body{
  background-color:#adb;
  margin:0;
  padding:0 0 0 150px;
}
div#left-sidebar{
 background-color:#bab;
 position:absolute;
 top:0;
 left:0;
 width:150px;
 height:100%;
}
@media screen{
 body>div#left-sidebar{
  position:fixed;
 }
}
* html body{
 overflow:hidden;
}
* html div#content{
 height:100%;
 overflow:auto;
}
ul.left-menu li {
    list-style-type:none;
    list-style-position:outside;
    width:100%;
}
ul.left-menu li.selected {
background-color:#adb;
}

