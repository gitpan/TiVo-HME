package TiVo::HME::Context;

use constant ID_CLIENT => 100;

sub new {
	my($class, %args) = @_;

	bless { %args, client_id => ID_CLIENT }, $class;
}

sub get_io {
	my($self) = @_;

	$self->{connexion};
}

sub get_next_id {
	my($self) = @_;

	$self->{client_id}++;
}

1;

