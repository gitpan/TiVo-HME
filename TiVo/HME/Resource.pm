package TiVo::HME::Resource;

use Digest::MD5 qw(md5_hex);

# stash of all current resources
our %_resources;
our @_resources;

# package globals
our $CONTEXT;
our $IO;
our %DEFAULT_RESOURCES;

our $VERSION = '1.0';

use constant {
	FONT_DEFAULT_ID => 10,
	FONT_SYSTEM_ID => 11,
	CMD_RSRC_ADD_COLOR => 20,
	CMD_RSRC_ADD_TTF => 21,
	CMD_RSRC_ADD_FONT => 22,
	CMD_RSRC_ADD_TEXT  => 23,
	CMD_RSRC_ADD_IMAGE  => 24,
	CMD_RSRC_ADD_SOUND  => 25,
	CMD_RSRC_ADD_STREAM  => 26,
	CMD_RSRC_ADD_ANIM  => 27,
	CMD_RSRC_SET_ACTIVE  => 40,
	CMD_RSRC_SET_POSITION  => 41,
	CMD_RSRC_SET_SPEED  => 42,
	CMD_RSRC_SEND_EVENT  => 44,
	CMD_RSRC_CLOSE  => 45,
	CMD_RSRC_REMOVE  => 46,
};

sub set_context {
	my($class, $context) = @_;

	$CONTEXT = $context;
	$IO = $context->get_io;

	# load up default sounds
	for (my $i = TiVo::HME::CONST->ID_BONK_SOUND; 
		$i <= TiVo::HME::CONST->ID_SPEEDUP3_SOUND; $i++) {

		$DEFAULT_RESOURCES[$i] = 
			bless { id => $i, what => 'sound' }, $class;
	}

}

sub get_id {
	$CONTEXT->get_next_id;
}

sub _make {
	my($class, $what, $id, $key) = @_;

	# store an extra ref to find easier later
	$_resources{$key} = bless {key => $key, what => $what, id => $id}, $class;
	$_resources[$id] = $_resources{$key};
}
	
sub color {
	my($class, $r, $g, $b, $alpha) = @_;

	$key = $r . $g . $b . $alpha;
	return $_resources{$key} if $_resources{key};

	# create color resource
	my $id = get_id;

	# ship it
	$IO->do('vvrrrr', CMD_RSRC_ADD_COLOR, $id, $alpha, $r, $g, $b);

	_make($class, 'color', $id, $key);
}

sub font {
	my($class, $name, $point_size, $style) = @_;
	my($key, $ttf_id, $id);

	$name = lc $name;
	return unless ($name =~ /system|default/);

	$key = $name . $point_size . $style;
	return $_resources{$key} if $_resources{key};

	$id = get_id;
	$ttf_id = $name eq 'system' ? FONT_SYSTEM_ID : FONT_DEFAULT_ID;

	# ship it
	$IO->do('vvvvf', CMD_RSRC_ADD_FONT, $id, $ttf_id, $style, $point_size);

	# store it
	_make($class, 'font', $id, $key);
}

sub text {
	my($class, $font, $color, $string) = @_;
	my($key, $id);

	$key = $font->{id} . $color->{id} . $string;
	return $_resources{$key} if $_resources{key};

	# create a new ID
	$id = get_id;

	# ship it
	$IO->do('vvvvs', CMD_RSRC_ADD_TEXT, $id, $font->{id}, $color->{id}, $string);

	# store it
	_make($class, 'text', $id, $key);
}

sub ttf_file {
	my($self, $fname) = @_;

	# TODO we should hash the file to see if we already got it...
	_binary_file($class, CMD_RSRC_ADD_TTF, $fname);
}

sub image_file {
	my($class, $fname) = @_;

	# TODO we should hash the file to see if we already got it...
	_binary_file($class, CMD_RSRC_ADD_IMAGE, $fname);
}

sub sound_file {
	my($class, $fname) = @_;

	# TODO we should hash the file to see if we already got it...
	_binary_file($class, CMD_RSRC_ADD_SOUND, $fname);
}

sub _binary_file {
	my($class, $opcode, $fname) = @_;

	my($size, $d) = -s $fname;
	open(F, $fname) || die "Can't open image file: $fname\n";
	binmode(F);
	my $s = sysread(F, $d, $size);
	close(F);

	if ($s != $size) {
		die "Error reading file $fname\n";
	}

	my $key = md5_hex($d);
	return $_resources{$key} if $_resources{key};

	my @data = split //, $d;

	# create a new ID
	$id = get_id;

	$IO->do('vvR', $opcode, $id, [map(ord, @data)]);

	_make($class, 'binary', $id, $key);
}

# $play 0 = pause 1 = play
sub stream {
	my($class, $url, $content_type, $play) = @_;

	my $key = $url . $content_type;
	return $_resources{$key} if $_resources{key};

	# create a new ID
	$id = get_id;
	$IO->do('vvssb', CMD_RSRC_ADD_STREAM, $id, $url, $content_type, $play);
	_make($class, 'stream', $id, $key);
}

# ease -1 = ease in, 0 = linear, 1 = ease out
sub animation {
	my($class, $duration, $ease) = @_;

	$ease ||= 0;

	my $key = $duration . $ease;
	return $_resources{$key} if $_resources{key};

	# create a new ID
	$id = get_id;
	$IO->do('vvvf', CMD_RSRC_ADD_ANIM, $id, $duration, $ease);
	_make($class, 'animation', $id, $key);
}

sub set_active {
	my($self, $active) = @_;
	$IO->do('vvb', CMD_RSRC_SET_ACTIVE, $self->{id}, $active);
}

sub set_position {
	my($self, $position) = @_;
	$IO->do('vvv', CMD_RSRC_SET_POSITION, $self->{id}, $position);
}

# 0 = paused, 1 = play
sub set_speed {
	my($self, $speed) = @_;
	$IO->do('vvf', CMD_RSRC_SET_SPEED, $self->{id}, $speed);
}

# $data is an ARRAY REF or whatever
sub send_event {
	my($class, $target_resource, $animation, $data) = @_;

	$aid = ($animation ? $animation->{id} : TiVo::HME::CONST->ID_NULL);

	$IO->do('vvvR', CMD_RSRC_SEND_EVENT, $target_resource->id, 
		$aid, $data);
}

sub close {
	my($self) = @_;
	$IO->do('vv', CMD_RSRC_CLOSE, $self->{id});
}

sub remove {
	my($self) = @_;

	if ($self->{id}) {
		$IO->do('vv', CMD_RSRC_REMOVE, $self->{id});
		undef $self->{id};
	}
}

sub make_key_event {
	my($class, $target, $action, $code, $rawcode) = @_;

	my @d;
	push @d, $IO->make_vint(TiVo::HME::CONST->EVT_KEY);
	push @d, $IO->make_vint($target->id);
	push @d, $IO->make_vint($action);
	push @d, $IO->make_vint($code);
	push @d, $IO->make_vint($rawcode);

	[ @d ];
}

sub DESTROY {
	my($self) = shift;
	$self->remove;
}

1;
