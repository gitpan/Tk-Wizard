
# $Id: fonts.t,v 1.1 2007/10/17 11:59:30 martinthurn Exp $

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
    plan tests => 26;
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk::Wizard::Tester');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

foreach my $iSize (4, 8, 12)
  {
  # diag(" DDD ENV{TEST_INTERACTIVE} is $ENV{TEST_INTERACTIVE}.");
  my $wizard = new Tk::Wizard::Tester(
                                      # -debug => 3,
                                      -basefontsize => $iSize,
                                      -wait => $ENV{TEST_INTERACTIVE} ? -1 : 444,
                                     );
  isa_ok( $wizard, "Tk::Wizard::Tester" );
  isa_ok( $wizard, "Tk::Wizard" );
  $wizard->Show;
  pass('before MainLoop');
  MainLoop;
  pass('after MainLoop');
  } # foreach
foreach my $sFont (qw( Arial Courier Times ))
  {
  # diag(" DDD ENV{TEST_INTERACTIVE} is $ENV{TEST_INTERACTIVE}.");
  my $wizard = new Tk::Wizard::Tester(
                                      # -debug => 3,
                                      -fontfamily => $sFont,
                                      -wait => $ENV{TEST_INTERACTIVE} ? -1 : 444,
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
