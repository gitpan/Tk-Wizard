#! perl -w
#
# Tk::Wizard test.pl - mailto:lgoddard@cpan.org
#
our $VERSION = 0.1;	# 29 November 2002 14:41 CET

use strict;
use Cwd;

print "1..4\n";

use Tk::Wizard;
use Tk::ProgressBar;
print "ok 1\n";

my $wizard = new Tk::Wizard(
	-title => "A title",
	-imagepath => cwd."/setup_blue.gif",
	-style	=> 'top',
	-topimagepath => cwd."/setup_blue_top.gif",
);

print ref $wizard eq "Tk::Wizard"? "ok 2\n" : "not ok 2\n";

$_ = $wizard->addPage( sub{
	return $wizard->blank_frame(-title=>"Welcome to the Wizard Test 'pb'",
		-text=>
			"This script tests and hopefully demonstrates the 'postNextButtonAction' feature.\n\n"
			."When you click Next, a Tk::ProgressBar widget should slowly be udpated."
		);
});

print $_==1? "ok 3\n":"not ok 3\n";

eval (' $_ = $wizard->addPage( "This will break" ) ');

print $@=~/addPage requires one or more CODE references as arguments/? "ok 4\n":"not ok 4\n";


exit;


