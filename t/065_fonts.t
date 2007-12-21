use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);
use WizTestSettings;

BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 21;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard');
    use_ok('WizTestSettings');
}

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

foreach my $iSize ( 4, 8, 12 ) {
    my $wizard = new Tk::Wizard(
        -basefontsize => $iSize,
    );
    isa_ok( $wizard, "Tk::Wizard" );

    WizTestSettings::add_test_pages(
		$wizard,
		-wait => $ENV{TEST_INTERACTIVE} ? -1 : 1,
	);

    $wizard->Show;
    pass('before MainLoop');
    MainLoop;
    pass('after MainLoop');

}

foreach my $sFont (qw( Arial Courier Times )) {
    my $wizard = new Tk::Wizard(
        -fontfamily => $sFont,
    );
    isa_ok( $wizard, "Tk::Wizard" );

    WizTestSettings::add_test_pages(
		$wizard,
		-wait => $ENV{TEST_INTERACTIVE} ? -1 : 1,
	);

    $wizard->Show;
    pass('before MainLoop');
    MainLoop;
    pass('after MainLoop');
}

pass 'after foreach loop';
