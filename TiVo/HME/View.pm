package TiVo::HME::View;

use constant {
	ID_NULL => 0x0,
	CMD_VIEW_ADD => 1,
	CMD_VIEW_SET_BOUNDS => 2,
	CMD_VIEW_SET_SCALE => 3,
	CMD_VIEW_SET_TRANSLATION => 4,
	CMD_VIEW_SET_TRANSPARENCY => 5,
	CMD_VIEW_SET_VISIBLE => 6,
	CMD_VIEW_SET_PAINTING => 7,
	CMD_VIEW_SET_RESOURCE => 8,
	CMD_VIEW_REMOVE => 9,

	# root view
	ID_ROOT_VIEW => 2,
};

# the root view
our $ROOT_VIEW;

sub new {
	my($class, %args) = @_;

	$self = bless { %args }, $class;
	if ($self->{id} == ID_ROOT_VIEW) {
		$ROOT_VIEW = $self;
	}

	# set ID & context
	$self->{id} = $ROOT_VIEW->{context}->get_next_id unless ($args{id});
	$self->{io} = $ROOT_VIEW->{context}->get_io;
	$self->{parent} ||= $ROOT_VIEW;

	$self;
}

sub add {
	my($self) = shift;

	$self->{io}->do('vvvvvvvb', 
		CMD_VIEW_ADD, $self->{id}, $self->{parent}->{id}, $self->{x},
		$self->{y}, $self->{width}, $self->{height}, $self->{visible});
	
	$self;
}

sub set_resource {
	my($self, $resource, $flags) = @_;

	$flags ||= TiVo::HME::CONST->HALIGN_LEFT;
	$self->{io}->do('vvvv', 
		CMD_VIEW_SET_RESOURCE, $self->{id}, $resource->{id}, $flags);
}

sub visible {
	my($self, $visible, $animation) = @_;

	$aid = ($animation ? $animation->{id} : ID_NULL);

	$self->{io}->do('vvbv', CMD_VIEW_SET_VISIBLE, $self->{id}, $visible, $aid);
}

sub bounds {
	my($self, $x, $y, $width, $height, $animation) = @_;

	$aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvvvvvv', 
		CMD_VIEW_SET_BOUNDS, $self->{id}, $x, $y, 
		$width, $height, $aid);
}

# $sx & $sy must be >= 0
sub scale {
	my($self, $sx, $sy, $animation) = @_;

	$aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvffv', CMD_VIEW_SET_SCALE, $self->{id}, 
		$sx, $sy, $aid);
}

sub translate {
	my($self, $tx, $ty, $animation) = @_;

	$aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvvvv', CMD_VIEW_SET_TRANSLATION, $self->{id}, 
		$tx, $ty, $aid);
}

# 0 = opaque 1 = transparent
sub transparency {
	my($self, $transparency, $animation) = @_;

	$aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvfv', CMD_VIEW_SET_TRANSPARENCY, $self->{id}, 
		$transparency, $aid);
}

# change appearance? true = yes
sub painting {
	my($self, $painting) = @_;

	$self->{io}->do('vvb', CMD_VIEW_SET_PAINTING, $self->{id}, $painting);
}

sub remove {
	my($self, $animation) = @_;

	if ($self->{id}) {
		$aid = ($animation ? $animation->{id} : ID_NULL);
		$self->{io}->do('vvv', CMD_VIEW_REMOVE, $self->{id}, $aid);
		undef $self->{id};
	}
}

sub width {
	$_[0]->{width};
}

sub height {
	$_[0]->{height};
}

sub DESTROY {
	my($self) = shift;
	$self->remove;
}

1;
