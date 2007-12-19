#! perl -w

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;

my $sMod;

BEGIN {
    use lib "../lib";
    $sMod = 'Tk::Wizard::Installer::Win32::Sizer';
    if ( $^O !~ m!win!i ) {
        plan 'skip_all' => 'This is not Windows';
    }    # if
    plan 'no_plan';
    use_ok('Tk::Wizard');
    use_ok($sMod);
}    # end of BEGIN block

our $VERSION = do { my @r = ( q$Revision: 1.8 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

pass('before new');
my $w = new $sMod(

    # -debug => 3,
    -height => 360,
);
isa_ok( $w, $sMod );
is(
    $w->addSplashPage(
        -wait  => 444,
        -title => "Welcome to the Wizard",
    ),
    1,
    'splash is 1'
);
my $s;
is(
    $w->addStartMenuPage(
        -wait => $ENV{TEST_INTERACTIVE} ? -1 : 999,
        -variable      => \$s,
        -program_group => 'My Group',
    ),
    2,
    'start menu page is 2'
);
is(
    $w->addSplashPage(
        -wait  => 444,
        -title => "Page Bye!",
        -text  => "Thanks for testing!"
    ),
    3,
    'bye is 3'
);
$w->Show;
pass('after Show');
MainLoop();
pass('after MainLoop');

__END__
