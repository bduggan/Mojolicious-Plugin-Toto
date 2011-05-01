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
    my ($self, $app) = @_;
    my $conf_file = basename($ENV{MOJO_EXE} || $0).'.toto';
    -e $conf_file or die("Cannot find $conf_file");
    $app->routes->route('/toto')->detour(app => Toto::app());

    my $conf = do $conf_file;
    my %conf = @$conf;
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

get '/' => { layout => "menu" } => 'top';

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
} => 'single';

1;
__DATA__
@@ layouts/menu.html.ep
% for my $noun (nouns) {
%= link_to url_for("plural", { controller => $noun }) => begin
%= $noun
%= end
% }
<div>
%= content
</div>

@@ layouts/menu_plurals.html.ep
% for my $noun (nouns) {
%= link_to url_for("plural", { controller => $noun }) => begin
%= $noun
%= end
% }
<div>
% for my $action (many($controller)) {
%= link_to url_for("plural", { controller => $controller, action => $action }) => begin
%= $action
%= end
% }
</div>
<div>
%= content
</div>

@@ layouts/menu_single.html.ep
% for my $noun (nouns) {
%= link_to url_for("plural", { controller => $noun }) => begin
%= $noun
%= end
% }
<div>
% for my $action (many($controller)) {
%= link_to url_for("single", { controller => $controller, action => $action, key => $key }) => begin
%= $action
%= end
% }
</div>
<div>
%= content
</div>

@@ single.html.ep
This is the page for a single <%= $controller %>

@@ plural.html.ep
your page to <%= $action %> <%= $controller %>s goes here<br>
(<%= $class =%>::<%= $action %>)

@@ top.html.ep
welcome to toto
