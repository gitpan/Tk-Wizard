#! perl -w
#
# Tk::Wizard test.pl - mailto:lgoddard@cpan.org
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################
use Test;
use strict;
use Tk::Wizard;
use Cwd;
BEGIN {
	warn "*"x70,"\nPlease agree to the licence to complete the test sucessfully.\n","*"x70,"\n";
	plan tests => 10;
};

our $VERSION = 0.2;	# 28 November 2002 11:24

ok(1);


#
# Instantiate Wizard
#

my $wizard = new Tk::Wizard(
	-title => "A title",
	-imagepath => cwd."/setup_blue.gif",
#	-style	=> 'top',
	-topimagepath => cwd."/setup_blue_top.gif",
);
ok(ref $wizard, "Tk::Wizard");
$wizard->configure(
	-preNextButtonAction => sub { &preNextButtonAction($wizard) },
	-finishButtonAction  => sub { ok(6);  },
);

#$wizard->Show();
#MainLoop;
#exit;

ok( ref $wizard->cget(-preNextButtonAction),"CODE");


#
# Create pages
#

our $SPLASH       	= $wizard->addPage( sub{ page_splash ($wizard)} );
ok($SPLASH,1);

our $COPYRIGHT_PAGE	= $wizard->addLicencePage( -filepath => cwd."/perl_licence_blab.txt" );
ok($COPYRIGHT_PAGE, 2);

$wizard->addPage( sub{ page_one($wizard) });

$wizard->addPage( sub{ page_two($wizard) });

our $user_chosen_dir;

our $GET_DIR 	= $wizard->addDirSelectPage ( -variable => \$user_chosen_dir );
ok($GET_DIR, 5);

$wizard->addPage( sub {
	return $wizard->blank_frame(
		-title=>"Finished",
		-subtitle => "Please press Finish to leave the Wizard.",
		-text => "By the way, you selected the directory $user_chosen_dir.\n\n"
		."If you saw some error messages, they came from Tk::DirTree, and show "
		."that some of your drives are inacessible - perhaps a CD-ROM drive without "
		."media.  Such warnings can be turned off - please see the documentation for details."
	);
});

ok(1);

ok(ref $wizard->parent, "Tk::Wizard" );

$wizard->Show();
MainLoop;
ok(1);
exit;


sub page_splash { my $wizard = shift;
	my ($frame,@pl) = $wizard->blank_frame(-title=>"Welcome to the Wizard",
	-subtitle=>"Wizard Test Wizard",
	-text=>
		"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page."
	);
	return $frame;
}


sub page_one { my $wizard = shift;
	my $frame = $wizard->blank_frame(
		-title=>"-title here",
		-subtitle=>'The text found in the -subtitle paramter appears here on the screen; quite a long string I trust: and sadly ugly still',
		-text=>"-text goes here.\n\nTk::Wizard is but a baby, and needs your help to grow into a happy, healthy, well-adjusted widget. Sadly, I've only been using Tk::* for a couple of weeks, and all this packing takes a bit of getting used to. And I'm also working to a deadline on the project which bore this Wizard, so please excuse some coding which is currently rather slip-shod, but which be tightened in the future."
	);
	return $frame;
}

sub page_two { my $wizard = shift;
	my $frame = $wizard->blank_frame(
		-title=>"The Title",
		-text=>"A page without a -subtitle."
	);
	return $frame;
}


sub preNextButtonAction { my $wizard = shift;
	$_ = $wizard->currentPage;
	if (/^$COPYRIGHT_PAGE$/){
		return $wizard->callback_licence_agreement;
	}
	elsif (/^$GET_DIR$/){
		$_ = $wizard->callback_dirSelect( \$user_chosen_dir );
		if ($_==1){
			$_ = chdir $user_chosen_dir;
			if (not $_){
				$wizard->parent->messageBox(-icon=>'warning',-title=>'Oops',
				-text=>"Please choose a valid directory.");
			}
		}
		return $_? 1 : 0;
	}
	return 1;
}

__END__
