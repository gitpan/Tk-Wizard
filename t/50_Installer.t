
# $Id: 50_Installer.t,v 1.9 2007/08/10 03:12:37 martinthurn Exp $

use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.9 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use LWP::UserAgent;
use Test::More;
use Tk;

BEGIN
  {
  my $mwTest;
  eval { $mwTest = Tk::MainWindow->new };
  if ($@)
    {
    plan skip_all => 'Test irrelevant without a display';
    exit;
    } # if
  $mwTest->destroy if Tk::Exists($mwTest);
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);
  $ua->env_proxy;
  my $response = $ua->get('http://search.cpan.org/');
  if ( $response->is_error )
    {
    plan skip_all => "LWP cannot get cpan, guess we're not able to get online";
    exit;
    } # if
  plan tests => 19;
  pass('can get cpan');
  use_ok("Tk::Wizard");
  use_ok("Tk::Wizard::Installer");
  } # end of BEGIN block

my $WAIT = 100;
my $sTestDir = 't/__perlwizardtest';
my $files = {
             'http://www.cpan.org/' => "$sTestDir/cpan_index1.html",
             'http://www.cpan.org/' => "$sTestDir/cpan_index2.html",
             'http://www.leegoddard.net' => "$sTestDir/lee.html",
            };

if ( ! -e $sTestDir )
  {
  $files->{'http://localhost/test.txt'} = "$sTestDir/test2.txt";
  } # if

my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok(
   $wizard->configure(
                      -preNextButtonAction => sub { &preNextButtonAction($wizard); },
                      -finishButtonAction  => sub { pass('Finished'); 1; },
                     ),
   'Configure'
  );

isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );
isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

# Create pages
#
my $SPLASH = $wizard->addPage( sub { page_splash($wizard) } );
is( $SPLASH, 1, 'Splash page is first' );

ok(
   $wizard->addDownloadPage(
                            -wait  => $WAIT,
                            -files => $files,
                            #-on_error => 1,
                            -no_retry => 1,
                           ),
   'addDownloadPage'
  );

ok(
   $wizard->addPage(
                    sub {
                      return $wizard->blank_frame(
                                                  -wait     => $WAIT,
                                                  -title    => "Finished",
                                                  -subtitle => "Please.",
                                                 );
                      }
                   ),
   'Add finish page'
  );

isa_ok( $wizard->{wizardPageList}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{wizardPageList} } ), 3, 'Number of pages' );
foreach ( 1 .. 3 )
  {
  isa_ok( $wizard->{wizardPageList}->[0], 'CODE', 'Page in list' );
  } # foreach

ok( $wizard->Show, "Show" );
Tk::Wizard::Installer::MainLoop();
pass("Exited MainLoop" );
unlink $sTestDir;
exit;

sub page_splash
  {
  my $wizard = shift;
  my ( $frame, @pl ) = $wizard->blank_frame(
                                            -wait  => $WAIT,
                                            -title => "Installer Test",
                                            -subtitle => "Testing",
                                           );
  return $frame;
  } # page_splash

sub preNextButtonAction { return 1; }

__END__
