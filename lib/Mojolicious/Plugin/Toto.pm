=head1 NAME

Mojolicious::Plugin::Toto - the toto navigational structure

=head1 DESCRIPTION

package Mojolicious::Plugin::Toto;

=head1 SEE ALSO

http://clagnut.com/sandbox/csstabs/

=cut

package Mojolicious::Plugin::Toto;
use File::Basename qw/basename/;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;

sub register {
    my $self     = shift;
    my $app      = shift;
    my $location = ( !ref $_[0] ? shift : "/toto" );
    my $conf     = shift;
    my %conf     = @$conf;

    $app->routes->route($location)->detour(app => Toto::app());

    my @nouns = grep !ref($_), @$conf;
    for ($app, Toto::app()) {
        $_->helper( toto_config => sub { @$conf } );
        $_->helper( app_name    => sub { basename($ENV{MOJO_EXE}) });
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

get '/' => { layout => "menu", controller => 'top' } => 'toto';

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
% my $key = stash 'key';
<ul class="globalnav" <%== $key ? q[id="globalnav_with_item"] : "" %>>
% for my $noun (nouns) {
<li>
% my $class=($noun eq $controller ? "here" : "");
%= link_to url_for("plural", { controller => $noun }) => class => $class => begin
<%= $noun =%>s
%= end
% next unless $noun eq $controller;
%= content "second_header";
% } continue {
</li>
% }
</ul>
<div id="content">
%= content
</div>
</body>
</html>

@@ layouts/menu_plurals.html.ep
% layout 'menu';
%= content second_header => begin
<ul>
% for my $a (many($controller)) {
<li>
% my $class = $action eq $a ? "here" : "";
%= link_to url_for("plural", { controller => $controller, action => $a }) => class => $class => begin
%= $a
%= end
</li>
% }
</ul>
% end

@@ layouts/menu_single.html.ep
% layout 'menu';
%= content second_header => begin
<ul class="item">
<li class="selected_item">
<%= $controller %> <%= $key %>
</li>
% for my $a (one($controller)) {
<li>
% my $class = $action eq $a ? "here" : "";
%= link_to url_for("single", { controller => $controller, action => $a, key => $key }) => class => $class => begin
%= $a
%= end
</li>
% }
</ul>
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
<center>
<br>
Welcome to <%= app_name %><br>
Please choose a menu item.
</center>

@@ toto.css
.globalnav {
	position:relative;
	float:left;
	width:100%;
	padding:0 0 1.75em 1em;
	margin:0;
	list-style:none;
	line-height:1em;
}

.globalnav LI {
	float:left;
	margin:0;
	padding:0;
}

.globalnav A {
	display:block;
	color:#444;
	text-decoration:none;
	font-weight:bold;
	background:#ddd;
	margin:0;
	padding:0.25em 1em;
	border-left:1px solid #fff;
	border-top:1px solid #fff;
	border-right:1px solid #aaa;
}

.globalnav A:hover,
.globalnav A:active,
.globalnav A.here:link,
.globalnav A.here:visited {
	background:#bbb;
}

.globalnav A.here:link,
.globalnav A.here:visited {
	position:relative;
	z-index:102;
}

/*subnav*/

.globalnav UL {
	position:absolute;
	left:0;
	top:1.5em;
	float:left;
	background:#bbb;
	width:100%;
	margin:0;
	padding:0.25em 0.25em 0.25em 1em;
	list-style:none;
	border-top:1px solid #fff;
}

#globalnav_with_item {
	padding:0 0 4.75em 1em;
}

.globalnav UL li.selected_item {
    color:red;
    float:none;
    text-align:center;
}

.globalnav UL LI {
	float:left;
	display:block;
	margin-top:1px;
}

.globalnav UL A {
	background:#bbb;
	color:#fff;
	display:inline;
	margin:0;
	padding:0 1em;
	border:0
}

.globalnav UL A:hover,
.globalnav UL A:active,
.globalnav UL A.here:link,
.globalnav UL A.here:visited {
	color:#444;
}
div.item {
    border:1px solid black;
    z-index:109;
    width:100%;
    text-align:center;
    font-weight:bold;
}
