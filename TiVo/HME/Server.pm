package TiVo::HME::Server;

use TiVo::HME::IO;
use TiVo::HME::Context;

use Digest::MD5 qw(md5_hex);
use CGI::Cookie;
use HTTP::Daemon;
use HTTP::Status;

use constant DEFAULT_PORT => 7288;
use constant ACCEPTOR_NAME => 'Acceptor';
use constant MAGIC => 0x53425456;
use constant VERSION_MAJOR => 0;
use constant VERSION_MINOR => 36;
use constant VERSION => (VERSION_MAJOR << 8) | VERSION_MINOR;
use constant VERSION_STRING => VERSION_MAJOR . '.' . VERSION_MINOR;
use constant MIME_TYPE => 'application/x-hme';
use constant TIVO_DURATION => 'X-TiVo-Accurate-Duration';

sub new {
	my ($class) = shift;
	my $d = HTTP::Daemon->new(
		LocalPort => DEFAULT_PORT,
		ReuseAddr => 1,
		ReusePort => 1,
	);
	#print "Please contact me at: <URL:", $d->url, ">\n";

	my $self = { server => $d };
	bless $self, $class;
}

sub start {
	my ($self) = shift;
	while (my($c, $peer) = $self->{server}->accept) {
		while (my $r = $c->get_request) {
			$c->autoflush;

			if ($r->method eq 'GET') {
				# do something w/cookie...
				my %cookies = CGI::Cookie->parse($r->header('Cookie'));
				my $id;

				$c->send_status_line;
				$c->print('Content-type: ' . MIME_TYPE);
				$c->send_crlf;
				# drop in a cookie
				unless (%cookies) {
					$id = generate_id();
					my $cookie = new CGI::Cookie(-name => 'id',
											-value => $id,
											-expires => '+20Y',
											-path => '/');
					$c->print("Set-Cookie: $cookie");
					$c->send_crlf;
				} else {
					$id = (keys %cookies)[0];
					$id = $cookies{$id}->value;
				}

				#end header
				$c->send_crlf;

				# dump SBTV & VERSION
				$c->print(pack('N', MAGIC));
				$c->print(pack('N', 0x0, 0x0, VERSION_MAJOR, VERSION_MINOR));

				my($magic, $rv);

				$c->sysread($magic, 4);
				die "Bad Magic!\n" if ($magic ne 'SBTV');

				$c->sysread($rv, 4);
				$rv = unpack('N', $rv);
				die "Bad Version!\n" if ($rv != VERSION);

				# New chunked encoded IO stream
				my $io = TiVo::HME::IO->new($c);

				# Create a new App Context
				my $context = TiVo::HME::Context->new(
					cookie => $id,
					connexion => $io,
					request => $r,
					peer => $peer,
				);

				# Create the App
				my $app_name;
				($app_name .= $r->url->path) =~ s#/##g;
				$app_name = $app_name . '.pm';
				eval { require "$app_name" };
				die "$@" if ($@);

				my $obj_name;
				($obj_name = $app_name) =~ s/\.pm$//;

				# Sorta assuming app object is a subclass of
				#	TiVo::HME::Application
				my $app = $obj_name->new;
				$app->set_context($context);
				$app->init($context);
				$app->read_events;
			}
			else {
				$c->send_error(RC_FORBIDDEN)
			}
		}
		$c->close;
		undef($c);
	}
}

# ** Note ** This is intended to be unique, not unguessable. 
sub generate_id {
	my $id = md5_hex(md5_hex(time.{}.rand().$$)); 
	$id =~ tr|+/=|-_.|;     # make non-word characters URL friendly 
	$id;
}

1;
