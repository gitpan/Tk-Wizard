#!perl -w

# This is an example of using a Wizard embedded in an application.

use strict;
use warnings;

use Tk;
use Tk::Wizard;

my $mw = new MainWindow;
our $wizard;

$wizard = $mw->Wizard(
                      # -debug => 1,
                      -title => 'Component Wizard',
                      -style => 'top',
                      -tag_text => "Component Wizard",
                      # THE NEXT LINE IS VITAL!
                      -finishButtonAction  => sub { $wizard->withdraw; return 1; }
                     );
$wizard->addPage( sub
                    {
                    $wizard->blank_frame(
                                         -title => "First Frame",
                                         -subtitle => "Step by step setup",
                                         -text => "This wizard will guide you through the complete setup"
                                        );
                    }
                );
$wizard->addPage( sub
                    {
                    $wizard->blank_frame(
                                         -title => "Last Frame",
                                         -subtitle => "LAST step setup",
                                         -text => "LAST test text"
                                        );
                    }
                );

$mw->Label(
           -text => "This is the application's MainWindow.",
          )->pack;
$mw->Label(
           -text => "When you click this button, the Wizard will start.",
          )->pack;
my $button = $mw->Button(
                         -text => "Start Wizard",
                         -command => sub {
                           $wizard->Show();
                           }
                        )->pack();

MainLoop;

__END__
