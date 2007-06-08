#! perl -w

use strict;
use ExtUtils::testlib;
use Test::More 'no_plan';

BEGIN {
    use_ok('Tk::Wizard');
}

my $VERSION = do { my @r = ( q$Revision: 1.6 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $iWIN32 = ( $^O =~ m!win!i ) ? 1 : 0; # Catches Cygwin and MsWin32
SKIP: {
    skip 'because this computer is not Cygwin or MSWin32', 1 if !$iWIN32;
    use_ok("Tk::Wizard::Installer::Win32");
}

__END__
