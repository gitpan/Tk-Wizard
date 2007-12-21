
# $Id: 22_skip.t,v 1.4 2007/06/08 00:57:01 martinthurn Exp $

use strict;
use warnings;

use Cwd;
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
        plan "no_plan";    # TODO Can't count tests atm
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('WizTestSettings');
    use_ok('Tk::Wizard');
}

my $VERSION = do { my @r = ( q$Revision: 1.4 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $wizard = new Tk::Wizard(
    -debug => undef,
    -title => "Test of Skip",
    -style => 'top',
);
isa_ok( $wizard, "Tk::Wizard" );

my $sMsg = q'YOU SHOULD NOT SEE THIS';
foreach ( 1 .. 5 ) {
    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -wait     => 100,
                    -title    => "Title One",
                    -subtitle => "It's just a test",
                    -text     => "This Wizard is a simple test of the Skip mechanism.",
                );
            },
        )
    );
    my $i = $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait     => 900,
                -title    => $sMsg,
                -subtitle => $sMsg,
                -text     => "\n\n\n$sMsg",
            );
        },
    );
    ok($i);
    $wizard->setPageSkip($i);
}    # foreach

# Make sure the last page of the wizard is not set to skip:
ok(
    $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait     => 100,
                -title    => "Title One",
                -subtitle => "It's just a test",
                -text     => "This Wizard is a simple test of the Skip mechanism.",
            );
        },
    )
);
pass('before Show');
$wizard->Show;
pass('before MainLoop');
MainLoop;
pass('after MainLoop');
exit;
__END__
