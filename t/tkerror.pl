#! perl -w

# $Id: subtitle.t,v 1.1 2007/09/02 16:35:22 martinthurn Exp $

use strict;

use ExtUtils::testlib;
use IO::Capture::Stdout;
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

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 333;

my $oICS =  IO::Capture::Stdout->new;
my $wizard;
$wizard = Tk::Wizard->new(
                          -title => "Tk::Error Test",
                          # -debug => 88,
                          -preNextButtonAction   => sub { &preNextButtonAction($wizard) },
                         );
isa_ok( $wizard, "Tk::Wizard" );
is(
   $wizard->addPage(
                    sub {
                      $wizard->blank_frame(
                                           -wait  => 1000,
                                           -title => "Welcome to the Wizard",
                                          );
                      # $wizard->NO_SUCH_FUNCTION;
                      }, # sub
                   ), # addPage
   1,
   'splash is 1'
  );
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
   2,
   'bye is 2'
  );
$oICS->start;
$wizard->Show;
$oICS->stop;
pass('after Show');
MainLoop();
pass('after MainLoop');

sub preNextButtonAction
  {
  my $wizard = shift;
  $wizard->NO_SUCH_FUNCTION;
  system('no_such_program');
  pass;
  return 1;
  } # preNextButtonAction


__END__

