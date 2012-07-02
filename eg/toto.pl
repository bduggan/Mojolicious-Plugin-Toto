#!/usr/bin/env perl

use Mojolicious::Lite;

my @menu = (
        nav => [ qw{overview examples source feedback} ],
        sidebar => {
            overview => [
                qw{toto/about toto/elements toto/quickstart toto/inspiration toto/examples toto/download element}
            ],
            examples => [
                qw{example/list example},
            ],
            source => [
                qw{file/list file},
            ],
            feedback => [
                qw{comments/view comments/add},
            ],
        },
        tabs => {
                element => [ qw/description example/ ],
                example => [ qw/description source/ ],
                file => [ qw/pod raw git/ ],
        }
);

plugin toto => @menu;

app->start;

__DATA__

@@ toto/about.html.ep
<br>
<div class="hero-unit">
  <h1>Toto</h1>
  <p>A navigational structure based on tabs and objects.</p>
<br>
<h6>
<%= link_to "https://metacpan.org/module/Mojolicious::Plugin::Toto" => begin %>Mojolicious-Plugin-Toto<%= end %> 
uses
<%= link_to "https://metacpan.org/module/Mojolicious" => begin %>Mojolicious<%= end %> and
twitter bootstrap's <%= link_to "http://twitter.github.com/bootstrap/examples/fluid.html" => begin %>fluid layout example<%= end %>
to create a navigational structure and set of routes for a web application.
</h6>
<br>
  <p style='text-align:right;'>
    <%= link_to "toto/elements", class =>"btn btn-primary btn-large" => begin %>
      Learn more
    <%= end %>
  </p>
</div>

@@ toto/elements.html.ep
<p>
Each page in an application created with toto has :
<ul>
<li>a <%= link_to "element/default", { key => "navbar" } => begin %>nav bar<%= end %> at the top
<li>a <%= link_to "element/default", { key => "sidebar" } => begin %>side bar<%= end %> for secondary navigation
<li>a row of <%= link_to "element/default", { key => "tabs" } => begin %>tabs<%= end %>.
  There are only tabs on pages for which an <%= link_to "element/default", { key => 'object' } => begin %>object<%= end %>
 has been selected.
</ul>
</p>

</pre>
@@ toto/quickstart.html.ep
<div class="hero-unit">
<h2>
To see a sample toto site running, just <%= link_to "toto/download" => begin %>download<%= end %> toto, and run one of
the <%= link_to "toto/examples" => begin %>examples<%= end %>.
</h2>
<pre class="code">
$ cpanm Mojolicious::Plugin::Toto
$ ./eg/toto.pl daemon
</pre>
</div>

@@ toto/download.html.ep
<p><%= link_to "https://metacpan.org/module/Mojolicious::Plugin::Toto" => begin %>Mojolicious-Plugin-Toto<%= end %> is
 available on <%= link_to "http://cpan.org" => begin %>CPAN<%= end %>.</p>
<p>It can be downloaded from there directly, or using a tool, such as
 <%= link_to "https://metacpan.org/module/cpanm" => begin %>cpanm<%= end %>.
