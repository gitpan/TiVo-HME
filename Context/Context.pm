package TiVo::HME::Context;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

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
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME::Context - Perl extension for blah blah blah

=head1 SYNOPSIS

  use TiVo::HME::Context;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for TiVo::HME::Context, created by h2xs. It looks like the
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
