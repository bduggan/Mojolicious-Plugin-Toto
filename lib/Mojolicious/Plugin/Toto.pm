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
        $_->helper( many        => sub { my $c = shift; @{ $menu{ $_[1] || $c->stash("controller") }{many} } } );
        $_->helper( one         => sub { my $c = shift; @{ $menu{ $_[1] || $c->stash("controller") }{one} } } );
        $_->helper(
            actions => sub {
                my $c = shift;
                defined( $c->stash("key") ) ? $c->one : $c->many;
            }
        );
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

get '/' => { layout => "menu", controller => '', action => '', actions => '' } => 'toto';

get '/toto.css' => sub { shift->render_static("toto.css") };

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
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
<title><%= title %></title>
%= stylesheet '/app/toto.css';
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

<div class="container">
    <ul class="tabs">
% for my $c (nouns) {
        <li <%== $c eq $controller ? q[ class="active"] : "" =%>>
            <%= link_to 'plural', { controller => $c } => begin =%><%= $c =%><%= end =%>
        </li>
% }
    </ul>
    <div class="tab_container">
        <div id="tab1" class="tab_content">
             <div class="toptab_container">
                <ul class="toptabs">
% for my $a (actions) {
                    <li><a href="#foo"><%= $a =%></a></li>
% }
                </ul>
             </div>
        </div>
    </div>
</div>

<script>
//Default Action
//$("ul.tabs li.active").show(); //Activate active tab
$(".tab_content").show(); //Show tab content
//On Click Event
$("ul.tabs li").click(function() {
    $("ul.tabs li").removeClass("active"); //Remove any "active" class
    $(this).addClass("active"); //Add "active" class to selected tab
    $(".tab_content").hide(); //Hide all tab content
    var activeTab = $(this).find("a").attr("href"); //Find the active tab + content
    $(activeTab).fadeIn(); //Fade in the active content
    return false;
});
$(".toptab_container").tabs();
</script>

<style>
body {
    background: #f0f0f0;
    margin: 0;
    padding: 0;
    font: 10px normal Verdana, Arial, Helvetica, sans-serif;
    color: #444;
}
.container {width: 90% margin: 10px auto;}
ul.tabs {
    margin: 0;
    padding: 0;
    float: left;
    list-style: none;
    height: 32px;
    border-bottom: 1px solid #999;
    border-left: 1px solid #999;
    width: 15%;
}
ul.tabs li {
    float: top;
    margin: 0;
    padding: 0;
    height: 31px;
    line-height: 31px;
    border: 1px solid #999;
    border-left: none;
    margin-bottom: 0px;
    background: #e0e0e0;
    overflow: hidden;
    position: relative;
}
ul.tabs li a {
    text-decoration: none;
    color: #000;
    display: block;
    font-size: 1.2em;
    padding: 0 20px;
    border: 1px solid #fff;
    outline: none;
}
ul.tabs li a:hover {
    background: #ccc;
}   
html ul.tabs li.active, html ul.tabs li.active a:hover  {
    background: #fff;
    border-bottom: 1px solid #fff;
}
.tab_container {
    border: 1px solid #999;
    width: 200%;
    background: #fff;
    margin-left:15%;
    -moz-border-radius-bottomright: 5px;
    -khtml-border-radius-bottomright: 5px;
    -webkit-border-bottom-right-radius: 5px;
    -moz-border-radius-bottomleft: 5px;
    -khtml-border-radius-bottomleft: 5px;
    -webkit-border-bottom-left-radius: 5px;
}
.tab_content {
    min-height: 360px;
    font-size: 1.2em;
}
.tab_content h2 {
    font-weight: normal;
    padding-bottom: 10px;
    font-size: 1.8em;
}
</style>
</html>

@@ layouts/menu_plurals.html.ep
% layout 'menu';
%= content second_header => begin
<ul class="ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
% for my $a (many($controller)) {
<li class="ui-state-default ui-corner-top">
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
<ul class="ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
% for my $a (one($controller)) {
<li class="ui-state-default ui-corner-top">
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
html,body {
    height:90%;
    }
