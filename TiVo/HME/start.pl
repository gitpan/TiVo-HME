#!perl

use lib qw(examples .. ../..);
use TiVo::HME::Server;

my $hme = TiVo::HME::Server->new;
$hme->start;

