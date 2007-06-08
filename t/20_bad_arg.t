
# $Id: 20_bad_arg.t,v 1.6 2007/06/08 00:57:01 martinthurn Exp $

use strict;

use ExtUtils::testlib;
use Test::More ;
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
  use_ok('Tk');
  use_ok('Tk::Wizard');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.6 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $wizard = new Tk::Wizard( -title => "Bad Argument Test", );
isa_ok( $wizard, "Tk::Wizard" );

my $i1 = $wizard->addPage(
    sub {
        return $wizard->blank_frame(
            -title => "title",
            -text  => 'test',
        );
    }
);
is( $i1, 1 );

eval(' $wizard->addPage( "This will break" ) ');
like( $@, qr/addPage requires one or more CODE references as arguments/ );

exit;

__END__


