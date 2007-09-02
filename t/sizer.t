
# $Id: sizer.t,v 1.3 2007/09/02 16:11:57 martinthurn Exp $

use strict;

my $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Cwd;
use ExtUtils::testlib;
use IO::Capture::Stdout;
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
    plan 'no_plan';
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk::Wizard::Sizer');
  } # end of BEGIN block
my $oICS =  IO::Capture::Stdout->new;
my $sStyle = 'top';
my $self = new Tk::Wizard::Sizer(
                                 # -debug => 3,
                                 -title => "Sizer Test",
                                 -style => $sStyle,
                                );
isa_ok( $self, "Tk::Wizard" );
isa_ok( $self, "Tk::Wizard::Sizer" );
our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 222;
my $s1 = "This is the long horizontal text for the Sizer TextFrame Page.  It is wider than the default Wizard width.";
my $s2 = "It is stored in a string variable, and a reference to this string variable is passed to the addTextFramePage() method.";
my $s3 = "This
 is
 the
 long
 vertical
 text
 for
 the
 Sizer
 TextFrame
 Page.  
It 
is 
 taller 
than 
the 
default 
Wizard 
height.";
$self->addPage(sub
                 {
                 $self->blank_frame(
                                    -wait => $WAIT,
                                    -title => "Intro Page Title ($sStyle style)",
                                    -subtitle => "Intro Page Subtitle ($sStyle style)",
                                    -text => "This is the text of the Sizer TextFrame Intro Page ($sStyle style)",
                                   );
                 } # sub
              ); # add_page
$self->addTextFramePage(
                        -wait => $WAIT,
                        -title => "Sizer TextFrame Page Title ($sStyle style)",
                        -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style)",
                        -text => $s1,
                        -boxedtext => \$s2,
                       );
$self->addTextFramePage(
                        -wait => $WAIT,
                        -title => "Sizer TextFrame Page Title ($sStyle style)",
                        -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style)",
                        -text => $s3,
                        -boxedtext => \$s2,
                       );
$self->addPage(sub
                 {
                 $self->blank_frame(
                                    -wait => $WAIT,
                                    -title => "Finish Page Title ($sStyle style)",
                                    -subtitle => "Finish Page Subtitle ($sStyle style)",
                                    -text => "This is the text of the Sizer TextFrame Finish Page ($sStyle style)",
                                   );
                 } # sub
              ); # add_page
pass('before Show');
$oICS->start;
$self->Show;
pass('before MainLoop');
MainLoop;
pass('after MainLoop');
$oICS->stop;
my @asOut = $oICS->read;
my $sOut = join('', @asOut);
# diag($sOut);
my $i = 0;
$i++ while ($sOut =~ m!final dimensions were!g);
is($i, 4, 'reported dimensions for 4 pages');
like($sOut, qr/smallest area/, 'reported overall best size');

if ($ENV{TEST_INTERACTIVE})
  {
  # Show the same Wizard with the sizes we determined empirically:
  my $self = new Tk::Wizard::Sizer(
                                   # -debug => 3,
                                   -title => "Sizer Test",
                                   -style => $sStyle,
                                  );
  isa_ok( $self, "Tk::Wizard" );
  isa_ok( $self, "Tk::Wizard::Sizer" );
  $self->addPage(sub
                   {
                   $self->blank_frame(
                                      -wait => $WAIT,
                                      -title => "Intro Page Title ($sStyle style)",
                                      -subtitle => "Intro Page Subtitle ($sStyle style)",
                                      -text => "This is the text of the Sizer TextFrame Intro Page ($sStyle style)",
                                      -width => 382, -height => 321,
                                     );
                   } # sub
                ); # add_page
  $self->addTextFramePage(
                          -wait => $WAIT,
                          -title => "Sizer TextFrame Page Title ($sStyle style)",
                          -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style)",
                          -text => $s1,
                          -boxedtext => \$s2,
                          -width => 655, -height => 220,
                         );
  $self->addTextFramePage(
                          -wait => $WAIT,
                          -title => "Sizer TextFrame Page Title ($sStyle style)",
                          -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style)",
                          -text => $s3,
                          -boxedtext => \$s2,
                          -width => 207, -height => 422,
                         );
  $self->addPage(sub
                   {
                   $self->blank_frame(
                                      -wait => $WAIT,
                                      -title => "Finish Page Title ($sStyle style)",
                                      -subtitle => "Finish Page Subtitle ($sStyle style)",
                                      -text => "This is the text of the Sizer TextFrame Finish Page ($sStyle style)",
                                      -width => 362, -height => 315,
                                     );
                   } # sub
                ); # add_page
  pass('before Show');
  $self->Show;
  pass('before MainLoop');
  MainLoop;
  pass('after MainLoop');
  } # if

__END__

