use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 2.072 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib "../lib";
use WizTestSettings;

BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 10;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard' => 2.072) or BAIL_OUT;
}

# $ENV{TEST_INTERACTIVE} = 1;

foreach my $style ( qw(top 95)) {

    my $wizard = Tk::Wizard->new(
        -background => 'blue',
        -style      => $style,
        -debug		=> 1,
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

pass('after foreach loop');
exit 0;

__END__
