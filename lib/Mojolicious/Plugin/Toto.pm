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
use strict;
use warnings;

our $VERSION = 0.01;

sub register {
    my $self     = shift;
    my $app      = shift;
    my $conf     = shift;
    my $location = $conf->{path} || '/toto';
    my @menu     = @{$conf->{menu} || []};
    my %menu     = @menu;

    $app->routes->route($location)->detour(app => Toto::app());

    my @nouns = grep !ref($_), @menu;
    for ($app, Toto::app()) {
        $_->helper( toto_menu   => sub { @menu } );
        $_->helper( app_name    => sub { basename($ENV{MOJO_EXE}) });
        $_->helper( nouns       => sub { @nouns } );
        $_->helper( many        => sub { @{ $menu{ $_[1] }{many} } } );
        $_->helper( one         => sub { @{ $menu{ $_[1] }{one} } } );
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

get '/' => { layout => "menu", controller => undef, action => undef, actions => undef } => 'toto';

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
    my $root = $c->app->renderer->root;
    my ($template) = grep {-e "$root/$_.html.ep" } "$controller/$action", $action;
    $c->stash->{template} = $template || 'plural';
    $c->stash(actions => [$c->many($controller) ]);
    $c->render(class => $class) unless $class->can($action);
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
    my $root = $c->app->renderer->root;
    my ($template) = grep {-e "$root/$_.html.ep" } "$controller/$action", $action;
    $c->stash->{template} = $template || 'single';
    $c->stash(actions => [ $c->one($controller) ]);
    $c->render(class => $class) unless $class->can($action);
} => 'single';

1;
__DATA__
@@ layouts/menu.html.ep
% use List::MoreUtils qw/first_index/;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
<title><%= title %></title>
%= stylesheet '/toto.css';
<%= javascript 'http://ajax.googleapis.com/ajax/libs/jquery/1.5/jquery.min.js' %>
 <%= javascript begin %>
   if (typeof jQuery == 'undefined') {
     var e = document.createElement('script');
     e.src = '/js/jquery.js';
     e.type = 'text/javascript';
     document.getElementsByTagName("head")[0].appendChild(e);
   }
 <% end %>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.js"></script>
%= stylesheet 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.7/themes/smoothness/jquery-ui.css';
</head>
<body>

<script>
% my $s = first_index(sub {$_ eq $controller},nouns);
	$(function() {
		var tabs = $( "#tabs" ).tabs({
        selected: <%= $s || 0%>,
        select: function(event, ui) {
        var url = $.data(ui.tab, 'load.tabs');
        if( url ) {
            location.href = url;
            return false;
        }
        return true;
    }}
    );
	});
% my $t = first_index(sub {$_ eq $action},@$actions);
    $(function() {
		var tabs = $( "#second_tabs" ).tabs({
        selected: <%= $t || 0 %>,
        select: function(event, ui) {
        var url = $.data(ui.tab, 'load.tabs');
        if( url ) {
            location.href = url;
            return false;
        }
        return true;
    }}
    );
	});

</script>

<div id="tabs">
<ul>
% for my $noun (nouns) {
<li>
%= link_to url_for("plural", { controller => $noun }) => begin
<%= $noun =%>s
%= end
</li>
% }
</ul>

<div id="second_tabs">
%= content "second_header";
%= content
</div>

</div>
</body>
</html>

@@ layouts/menu_plurals.html.ep
% layout 'menu';
%= content second_header => begin
<ul>
% for my $a (many($controller)) {
<li>
%= link_to url_for("plural", { controller => $controller, action => $a }) => begin
%= $a
%= end
</li>
% }
</ul>
% end

@@ layouts/menu_single.html.ep
% layout 'menu';
%= content second_header => begin
<center><%= $controller %> <%= $key %></center>
<ul>
% for my $a (one($controller)) {
<li>
%= link_to url_for("single", { controller => $controller, action => $a, key => $key }) => begin
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
your page to <%= $action %> <%= $controller %>s goes here<br>
(add <%= $class %>::<%= $action %>)<br>
% for (1..10) {
%= link_to 'single', { controller => $controller, key => $_ } => begin
<%= $controller %> <%= $_ %><br>
%= end
% }

@@ toto.html.ep
<center>
<br>
Welcome to <%= app_name %><br>
Please choose a menu item.
</center>

@@ toto.css
ul.globalnav {
	position:relative;
	float:left;
	width:95%;
	padding:0 0 1.75em 1em;
	margin:0;
	list-style:none;
	line-height:1em;
    overflow:hidden;
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
	padding:0 0 2.75em 1em;
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
html,body {
    height:90%;
    }
div#content {
    margin:0;
	padding:0 0 2.75em 1em;
    clear:both;
    background-color:#abb;
    height:100%;
    width:95%;
}


