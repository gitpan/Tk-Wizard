#!perl -w

# This is an example of using a Wizard embedded in an application.

# Based on code supplied by Peter Weber.

use strict;
use warnings;

use ExtUtils::testlib;    # This lets you run this example before
                          # installing the module
use Tk;
use Tk::Wizard;

my $mw = new MainWindow;
our $wizard;

$wizard = $mw->Wizard(

    # -debug => 1,
    -title    => 'Component Wizard',
    -style    => 'top',
    -tag_text => "Component Wizard",
);
$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -title    => "First Frame",
            -subtitle => "Step by step setup",
            -text     => "This wizard will guide you through the complete setup"
        );
    }
);
$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -title    => "Second page",
            -subtitle => "Second step setup",
            -text     => "Second test text"
        );
    }
);
$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -title    => "Last Frame",
            -subtitle => "LAST step setup",
            -text     => "LAST test text"
        );
    }
);

$mw->Label( -text => "This is the application's MainWindow.", )->pack;
$mw->Label( -text => "When you click this button, the Wizard will start.", )->pack;
my $button = $mw->Button(
    -text    => "Start Wizard",
    -command => sub {
        $wizard->Show();
    }
)->pack();

MainLoop;

__END__
