=head1 NAME

Mojolicious::Plugin::Toto - the toto navigational structure

=head1 DESCRIPTION

This is an implementation of a navigational structure
I call "toto", an acronym for "tabs on this object".

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use strict;
use warnings;

our $VERSION = 0.01;

sub register {
    my ($self, $app, $conf) = @_;

    my $location = $conf->{path} || '/toto';
    my @menu     = @{$conf->{menu} || []};
    my %menu     = @menu;

    $app->routes->route($location)->detour(app => Toto::app());

    my @controllers = grep !ref($_), @menu;
    for ($app, Toto::app()) {
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
}

package Toto::Controller;
use Mojo::Base 'Mojolicious::Controller';

package Toto;
use Mojolicious::Lite;
use Mojo::ByteStream qw/b/;

get '/' => { layout => "menu", controller => '', action => '' } => 'toto';

get '/toto.css' => sub { shift->render_static("toto.css") };

get '/:controller/:action' => {
    action    => "default",
    namespace => "Toto::Controller",
    layout    => "menu"
  } => sub {
    my $c = shift;
    my ( $action, $controller ) = ( $c->stash("action"), $c->stash("controller") );
    if ($c->stash("action") eq 'default') {
        my $first = [ $c->actions ]->[0];
        return $c->redirect_to( "plural" => action => $first, controller => $controller )
    }
    my $class = join '::', $c->stash("namespace"), b($controller)->camelize;
    my $root = $c->app->renderer->root;
    my ($template) = grep {-e "$root/$_.html.ep" } "$controller/$action", $action;
    $c->stash->{template} = $template || 'plural';
    $c->render(class => $class) unless $class->can($action);
  } => 'plural';

get '/:controller/:action/(*key)' => {
    action => "default",
    namespace => "Toto::Controller",
    layout => "menu"
} => sub {
    my $c = shift;
    my ( $action, $controller, $key ) =
      ( $c->stash("action"), $c->stash("controller"), $c->stash("key") );
    if ($c->stash("action") eq 'default') {
        my $first = [ $c->actions ]->[0];
        return $c->redirect_to( "single" => action => $first, controller => $controller, key => $key )
    }
    my $class = join '::', $c->stash("namespace"), b($controller)->camelize;
    my $root = $c->app->renderer->root;
    my ($template) = grep {-e "$root/$_.html.ep" } "$controller/$action", $action;
    $c->stash->{template} = $template || 'single';
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
% for my $c (controllers) {
        <li <%== $c eq $controller ? q[ class="active"] : "" =%>>
            <%= link_to 'plural', { controller => $c } => begin =%><%= $c =%><%= end =%>
        </li>
% }
    </ul>
    <div class="tab_container">
         <div class="toptab_container">
% if (stash 'key') {
%= include 'top_tabs_single';
% } else {
%= include 'top_tabs_plural';
% }
         <div class="page_content">
         <%= content =%>
         </div>
         </div>
    </div>
</div>
<script>
//Default Action
//$("ul.tabs li.active").show(); //Activate active tab
$(".toptab_container").show(); //Show tab content
//On Click Event
$("ul.tabs li").click(function() {
    $("ul.tabs li").removeClass("active"); //Remove any "active" class
    $(this).addClass("active"); //Add "active" class to selected tab
    $(".toptab_container").hide(); //Hide all tab content
    var activeTab = $(this).find("a").attr("href"); //Find the active tab + content
    $(activeTab).fadeIn(); //Fade in the active content
    return false;
});
//$(".toptab_container").tabs();
$(".toptab_container").addClass("ui-tabs ui-widget ui-widget-content ui-corner-all");
$(".toptab_container ul").addClass("ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all");
$(".toptab_container ul li").addClass("ui-state-default ui-corner-top");
$(".toptab_container ul li.active").addClass("ui-state-active");
$(".toptab_container ul li").click(function() {
    $("ul.toptabs li").removeClass("ui-state-active");
    $(".page_content").hide();
    $(this).addClass("ui-state-active");
});

</script>
</html>

@@ top_tabs_plural.html.ep
<ul class="toptabs">
% for my $a (actions) {
    <li <%== $a eq $action ? q[ class="active"] : '' %>>
        <%= link_to 'plural', { controller => $controller, action => $a } => begin =%>
            <%= $a =%>
        <%= end =%>
    </li>
% }
</ul>

@@ top_tabs_single.html.ep
<h2><%= $controller %> <%= $key %></h2>
<ul class="toptabs">
% for my $a (actions) {
    <li <%== $a eq $action ? q[ class="active"] : '' %>>
        <%= link_to 'single', { controller => $controller, action => $a, key => $key } => begin =%>
            <%= $a =%>
        <%= end =%>
    </li>
% }
</ul>


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
% use File::Basename qw/basename/;
<center>
<br>
Welcome, to <%= basename($ENV{MOJO_EXE}) %><br>
Please choose a menu item.
</center>

@@ toto.css
html,body {
    height:95%;
    border:none;
    }
body {
    background: #f0f0f0;
    margin: 0;
    padding: 0;
    font: 10px normal Verdana, Arial, Helvetica, sans-serif;
    color: #444;
}
.container {width: 90% margin: 10px auto; height:95%;}
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
    background: #fff;
    height:95%;
    margin-left:15%;
    -moz-border-radius-bottomright: 5px;
    -khtml-border-radius-bottomright: 5px;
    -webkit-border-bottom-right-radius: 5px;
    -moz-border-radius-bottomleft: 5px;
    -khtml-border-radius-bottomleft: 5px;
    -webkit-border-bottom-left-radius: 5px;
}
.toptab_container {
    height: 100%;
    font-size: 1.2em;
}
.toptab_container h2 {
    text-align:center;
    font-weight: normal;
    font-size: 1.8em;
    height:5%;
}
.page_content {
    height:95%;
}
