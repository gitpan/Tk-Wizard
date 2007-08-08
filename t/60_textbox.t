
# $Id: 60_textbox.t,v 1.1 2007/08/08 04:21:18 martinthurn Exp $

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
    plan tests => 5;
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk::Wizard::Tester');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $iWait = $ENV{TEST_INTERACTIVE} ? 0 : 333;
my $wizard = new Tk::Wizard::Tester(
                                    # -debug => 3,
                                    -style => 'top',
                                    -wait => $iWait,
                                   );
isa_ok( $wizard, "Tk::Wizard::Tester" );
isa_ok( $wizard, "Tk::Wizard" );
my $text  = "This is in a box";
$wizard->addTextFramePage(
                          -wait => $iWait,
                          -title => "1: Text from literal",
                          -boxedtext => \$text,
                         );
$wizard->addTextFramePage(
                          -wait => $iWait,
                          -subtitle => "2: Text from filename",
                          -boxedtext => 'perl_licence_blab.txt',
                         );
$wizard->Show;
pass('before MainLoop');
MainLoop;
pass('after MainLoop');
exit 0;

__END__
