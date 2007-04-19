#! perl -w

use strict;
use ExtUtils::testlib;
use Test::More 'no_plan';

BEGIN
  {
  use_ok('Tk::Wizard');
  }

my $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

my $wizard = new Tk::Wizard(
                            -title => "Bad Argument Test",
                           );
isa_ok($wizard, "Tk::Wizard");

my $i1 = $wizard->addPage( sub{
                             return $wizard->blank_frame(-title => "title",
                                                         -text => 'test',
                                                        );
                             });
is($i1, 1);

eval(' $wizard->addPage( "This will break" ) ');
like($@, qr/addPage requires one or more CODE references as arguments/);

exit;

__END__


