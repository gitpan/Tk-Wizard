#! perl -w

# $Id: 77_dirselect.t,v 1.5 2007/06/08 00:57:01 martinthurn Exp $

use strict;

use Cwd;
use ExtUtils::testlib;
use FileHandle;
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

my $VERSION = do { my @r = ( q$Revision: 1.5 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

autoflush STDOUT 1;

our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 900;
my $sDir;

my $wizard = Tk::Wizard->new(
    -title =>
      "Test version $VERSION For Tk::Wizard version $Tk::Wizard::VERSION",

    # -debug => 88,
);
isa_ok( $wizard, "Tk::Wizard" );
$wizard->configure(
    -preNextButtonAction => sub { &preNextButtonAction($wizard) },
    -finishButtonAction  => sub { pass('user clicked finish'); 1; },
);
isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );
isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

#
# Create pages
#
is(
    $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait  => 100,
                -title => "Welcome to the Wizard",
            );
        }
    ),
    1,
    'splash is 1'
);
my $iGET_DIR = $wizard->addDirSelectPage(
    -wait       => $WAIT,
    -nowarnings => "9",
    -variable   => \$sDir,
);
is( $iGET_DIR, 2, 'dirselect is 2' );
is(
    $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait  => 100,
                -title => "Page Bye!",
                -text  => "Thanks for testing!"
            );
        }
    ),
    3,
    'bye is 3'
);
$wizard->Show;
pass('after Show');
MainLoop();
pass('after MainLoop');
undef $wizard;

sub preNextButtonAction {
    my $wizard = shift;
    my $iPage  = $wizard->currentPage;

# diag("start preNextButtonAction(iPage=$iPage), iGET_DIR=$iGET_DIR, wizard is $wizard");
    if ( $iPage == $iGET_DIR ) {
        my $i =
          $ENV{TEST_INTERACTIVE} ? $wizard->callback_dirSelect( \$sDir ) : 1;
        return $i;
        if ( $_ == 1 ) {
            $_ = chdir $sDir;
            if ( not $_ ) {
                $wizard->parent->messageBox(
                    -icon  => 'warning',
                    -title => 'Oops',
                    -text  => "Please choose a valid directory.",
                );
            }
        }    # if
        return $_ ? 1 : 0;
    }    # if
    return 1;
}    # preNextButtonAction

__END__
