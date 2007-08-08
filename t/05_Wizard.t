
# $Id: 05_Wizard.t,v 1.11 2007/08/08 04:19:13 martinthurn Exp $

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
    plan tests => 10;
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk::Wizard::Tester');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.11 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

foreach my $style ( 'top', '95' )
  {
  # diag(" DDD ENV{TEST_INTERACTIVE} is $ENV{TEST_INTERACTIVE}.");
  my $wizard = new Tk::Wizard::Tester(
                                      # -debug => 3,
                                      -style => $style,
                                      -wait => $ENV{TEST_INTERACTIVE} ? 0 : 444,
                                     );
  isa_ok( $wizard, "Tk::Wizard::Tester" );
  isa_ok( $wizard, "Tk::Wizard" );
  $wizard->Show;
  pass('before MainLoop');
  MainLoop;
  pass('after MainLoop');
  } # foreach
pass('after foreach loop');
exit 0;

__END__
