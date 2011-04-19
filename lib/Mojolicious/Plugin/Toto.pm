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

    for my $noun (@nouns) {
        $app->log->debug("Making controller class for $noun");
        my $new = join '::', qw/Toto Controller/, b($noun)->camelize->to_string;
        my $var = "@". join "::", $new, "ISA";
        eval "push $var, q[Toto::Controller]" unless $new->isa("Toto::Controller");
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

get '/' => { layout => "menu" } =>'top';

get '/:controller' => {
    action => "default",
    namespace => "Toto::Controller",
    layout => "menu"
    } => 'plural';

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

@@ plural.html.ep
<%= $controller %> (many) : <%= join ',', many($controller) %>

@@ top.html.ep
welcome to toto
