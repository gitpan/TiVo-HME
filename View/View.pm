package TiVo::HME::View;

use 5.008;
use strict;
use warnings;
our $VERSION = '1.1';

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

	my $self = bless { %args }, $class;
	if (defined $self->{id} && $self->{id} == ID_ROOT_VIEW) {
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

	my $aid = ($animation ? $animation->{id} : ID_NULL);

	$self->{io}->do('vvbv', CMD_VIEW_SET_VISIBLE, $self->{id}, $visible, $aid);
}

sub bounds {
	my($self, $x, $y, $width, $height, $animation) = @_;

	my $aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvvvvvv', 
		CMD_VIEW_SET_BOUNDS, $self->{id}, $x, $y, 
		$width, $height, $aid);
}

# $sx & $sy must be >= 0
sub scale {
	my($self, $sx, $sy, $animation) = @_;

	my $aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvffv', CMD_VIEW_SET_SCALE, $self->{id}, 
		$sx, $sy, $aid);
}

sub translate {
	my($self, $tx, $ty, $animation) = @_;

	my $aid = ($animation ? $animation->{id} : ID_NULL);
	$self->{io}->do('vvvvv', CMD_VIEW_SET_TRANSLATION, $self->{id}, 
		$tx, $ty, $aid);
}

# 0 = opaque 1 = transparent
sub transparency {
	my($self, $transparency, $animation) = @_;

	my $aid = ($animation ? $animation->{id} : ID_NULL);
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
		my $aid = ($animation ? $animation->{id} : ID_NULL);
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


__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME::View - Perl extension for blah blah blah

=head1 SYNOPSIS

  use TiVo::HME::View;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for TiVo::HME::View, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
