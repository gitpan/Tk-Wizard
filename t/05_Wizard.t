use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 1.14 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;

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
    use_ok('Tk::Wizard::Tester');
}

# $ENV{TEST_INTERACTIVE} = 1;

foreach my $style ( 'top', '95' ) {

    diag(" # # # ENV{TEST_INTERACTIVE} is $ENV{TEST_INTERACTIVE}");
    my $wizard = new Tk::Wizard::Tester(

        # -debug => 3,
        -background => 'blue',
        -style      => $style,
        -wait       => $ENV{TEST_INTERACTIVE} ? -1 : 444,
    );

    isa_ok( $wizard, "Tk::Wizard::Tester" );

    isa_ok( $wizard, "Tk::Wizard" );

    $wizard->Show;

    pass('before MainLoop');
    MainLoop;
    pass('after MainLoop');
}

pass('after foreach loop');
exit 0;

__END__
