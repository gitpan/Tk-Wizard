#! perl -w

# $Id: subtitle.t,v 1.1 2007/09/02 16:35:22 martinthurn Exp $

use strict;

use Cwd;
use ExtUtils::testlib;
use FileHandle;
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
  use_ok('Tk::Wizard::Sizer');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 3333;

my $oICS =  IO::Capture::Stdout->new;
my $wizard = Tk::Wizard::Sizer->new(
                                    -title => "Title Wrap Test",
                                    # -debug => 88,
                                   );
isa_ok( $wizard, "Tk::Wizard" );
is(
   $wizard->addPage(
                    sub {
                      $wizard->blank_frame(
                                           -wait  => 100,
                                           -title => "Welcome to the Wizard",
                                          );
                      }, # sub
                   ), # addPage
   1,
   'splash is 1'
  );
my $sLong = 'Does this long (sub)title wrap? ';
for ('a'..'z')
  {
  $sLong .= "$_ ";
  } # for
is($wizard->addPage(
                    sub
                      {
                      $wizard->blank_frame(
                                           -subtitle => $sLong,
                                           -title => $sLong,
                                           -wait => $WAIT,
                                          ); # blank_frame
                      }, # sub
                   ), # addPage
   2, 'subtitle page is 2' );
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
$oICS->start;
$wizard->Show;
$oICS->stop;
pass('after Show');
MainLoop();
pass('after MainLoop');

__END__

