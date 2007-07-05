
# $Id: 50_Installer.t,v 1.7 2007/06/11 00:44:10 martinthurn Exp $

my $VERSION = do { my @r = ( q$Revision: 1.7 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use warnings;
use strict;

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

my $WAIT  = 100;
my $files = {
             'http://www.cpan.org/'      => './cpan_index1.html',
             'http://www.cpan.org/'      => './cpan_index2.html',
             'http://www.leegoddard.net' => './lee.html',
            };

if ( ! -e 't/__perlwizardtest' )
  {
  $files->{'http://localhost/test.txt'} = 't/__perlwizardtest/test2.txt';
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
                                                  -subtitle => "Please press Finish to leave the Wizard.",
                                                  -text =>
                                                  "If you saw some error messages, they came from Tk::DirTree, and show "
                                                  . "that some of your drives are inacessible - perhaps a CD-ROM drive without "
                                                  . "media.  Such warnings can be turned off - please see the documentation for details."
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
unlink 't/__perlwizardtest';
exit;

sub page_splash {
    my $wizard = shift;
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Installer Test",
        -subtitle =>
          "Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
        -text => "This Wizard is a simple test of the Wizard, and nothing more.

No software will be installed, but you'll hopefully see a few things.

Latest addition: file download

"
    );
    return $frame;
}

sub preNextButtonAction { return 1; }

__END__
