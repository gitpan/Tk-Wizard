
# $Id: 05_Wizard.t,v 1.8 2007/06/08 00:57:00 martinthurn Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;
use Tk;

BEGIN
  {
  my $mwTest;
  eval { $mwTest = Tk::MainWindow->new };
  if ($@)
    {
    plan skip_all => 'Test irrelevant without a display';
    }
  else
    {
    plan "no_plan"; # TODO Can't count tests atm
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk::Wizard');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.8 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };


my $wizard;
$wizard = new Tk::Wizard(
                         # -debug => 3,
                         -title => "Test",
                         -style => 'top',
                        );
isa_ok( $wizard, "Tk::Wizard" );
ok
$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -wait     => 100,
            -title    => "Title One",
            -subtitle => "It's just a test",
            -text =>
"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
        );
    }
);
ok
$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -wait     => 100,
            -title    => "Title Two",
            -subtitle => "It's just a test",
            -text =>
"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
        );
    }
);
ok
$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -wait     => 100,
            -title    => "Title Three",
            -subtitle => "It's just a test",
            -text =>
"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
        );
    }
);

$wizard->Show;
MainLoop;
pass('after MainLoop');
exit;

__END__
