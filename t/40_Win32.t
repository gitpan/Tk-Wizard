#! perl -w

use strict;
use ExtUtils::testlib;
use Test::More 'no_plan';

BEGIN
  {
  use_ok('Tk::Wizard');
  }

my $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

my $iWIN32 = ($^O =~ m!win32!i) ? 1 : 0;
SKIP:
  {
  skip 'because this computer is not MSWin32', 1 if ! $iWIN32;
  use_ok("Tk::Wizard::Installer::Win32");
  } # end of SKIP block

__END__
