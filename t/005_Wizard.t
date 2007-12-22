use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 2.073 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

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
        plan tests => 9;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard' => 2.074) or BAIL_OUT "Is this a fake-log4perl error?";
    use_ok('WizTestSettings');
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


__END__
