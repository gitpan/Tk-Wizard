
# $Id: 22_skip.t,v 1.1 2007/05/01 21:05:27 martinthurn Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';

BEGIN
  {
  use_ok('Tk::Wizard');
  } # end of BEGIN block

my $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
use Cwd;

my $wizard = new Tk::Wizard(
                            -debug => undef,
                            -title => "Test of Skip",
                            -style => 'top',
                           );
isa_ok($wizard, "Tk::Wizard");

my $sMsg = q'YOU SHOULD NOT SEE THIS';
foreach (1..5)
  {
  ok($wizard->addPage(sub {
                        $wizard->blank_frame(
                                             -wait => 100,
                                             -title => "Title One",
                                             -subtitle =>"It's just a test",
                                             -text => "This Wizard is a simple test of the Skip mechanism.",
                                            );
                        },
                     ));
  my $i = $wizard->addPage(sub {
                             $wizard->blank_frame(
                                                  -wait => 900,
                                                  -title => $sMsg,
                                                  -subtitle => $sMsg,
                                                  -text => "\n\n\n$sMsg",
                                                 );
                             },
                          );
  ok($i);
  $wizard->setPageSkip($i);
  } # foreach
# Make sure the last page of the wizard is not set to skip:
ok($wizard->addPage(sub {
                      $wizard->blank_frame(
                                           -wait => 100,
                                           -title => "Title One",
                                           -subtitle =>"It's just a test",
                                           -text => "This Wizard is a simple test of the Skip mechanism.",
                                          );
                      },
                   ));
pass('before Show');
$wizard->Show;
pass('before MainLoop');
MainLoop;
pass('after MainLoop');
exit;
__END__
