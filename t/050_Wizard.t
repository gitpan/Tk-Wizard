use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 2.077 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);


BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 6;
    }
    $mwTest->destroy if Tk::Exists($mwTest);

#	If you get strange errors, increase the plan and try this test for Log4perl:
#	use_ok('Tk::Wizard' => '2.080');
#    is($Tk::Wizard::VERSION, "2.080", 'pm version') or BAIL_OUT "Is this a fake-log4perl error?";

	use_ok('Tk::Wizard');

    use_ok('WizTestSettings');
}

$ENV{TEST_INTERACTIVE} = 0;

# t/050_Wizard.............XStoSubCmd: Not a Tk Window
#  Tk::die_with_trace at /mnt/i386/usr/local/src/CPAN/build/Tk-Wizard-2.134-1roshM/blib/lib/Tk/Wizard.pm line 890
#  Tk::Wizard::_render_current_page at /mnt/i386/usr/local/src/CPAN/build/Tk-Wizard-2.134-1roshM/blib/lib/Tk/Wizard.pm line 1542
#  Tk::Wizard::Show at t/050_Wizard.t line 42

foreach my $style ( qw(top 95)) {

    my $wizard = Tk::Wizard->new(
        -style      => $style,
    );

    isa_ok( $wizard, "Tk::Wizard" );

    WizTestSettings::add_test_pages(
		$wizard,
		-wait => $ENV{TEST_INTERACTIVE} ? -1 : 1,
	);

    eval { $wizard->Show };

    if ($@){
		fail "Failed to show";
		warn $@;
	} else {
		MainLoop;
		pass 'after MainLoop';
	}
}

