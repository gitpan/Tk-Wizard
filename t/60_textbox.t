use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib "../lib";



BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 5;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard::Tester');
}


my $iWait = $ENV{TEST_INTERACTIVE} ? 0 : 333;
my $wizard = new Tk::Wizard::Tester(

    # -debug => 3,
    -style => 'top',
    -wait  => $iWait,
);
isa_ok( $wizard, "Tk::Wizard::Tester" );
isa_ok( $wizard, "Tk::Wizard" );
my $text = "This is in a box";
$wizard->addTextFramePage(
    -wait      => $iWait,
    -title     => "1: Text from literal",
    -boxedtext => \$text,
);
$wizard->addTextFramePage(
    -wait      => $iWait,
    -subtitle  => "2: Text from filename",
    -boxedtext => 'perl_licence_blab.txt',
);
$wizard->Show;
pass('before MainLoop');
MainLoop;
pass('after MainLoop');
exit 0;

__END__
