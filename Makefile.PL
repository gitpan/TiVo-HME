use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'TiVo::HME',
    VERSION_FROM      => 'TiVo/HME/Application.pm', # finds $VERSION
    PREREQ_PM         => { Digest::MD5 => 0,
                            IO::Select => 0,
                            HTTP::Daemon => 0,
                            HTTP::Status => 0,
                            CGI::Cookie => 0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT      => 'Pure Perl implementation of TiVo\'s HME protocol',
       AUTHOR        => 'Mark Ethan Trostler <mark@zzo.com>') : ()),
);
