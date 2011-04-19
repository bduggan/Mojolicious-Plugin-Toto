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
    for ($app, Toto::app()) {
        $_->helper(toto_config => sub { $conf });
    }

    my %conf = @$conf;
    for my $noun (keys %conf) {
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
    $c->render_text("this is the default for $c");
}

package Toto;
use Mojolicious::Lite;

get '/' => 'top';

get '/:controller' => {
    action => "default",
    namespace => "Toto::Controller"
    } => 'plural';

1;
__DATA__
@@ top.html.ep
config is:

<%= dumper(toto_config) =%>

