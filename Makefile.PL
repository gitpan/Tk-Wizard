use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %hsPrereq = (
		"Tk"				=> 0.1,
		"Tk::ProgressBar"	=> 0.1,
		"Tk::LabFrame"		=> 0.1,
		"File::Path"		=> 0.1,
		);
# "Thurn, Martin" <mthurn@northropgrumman.com>
if ($^O =~ m/(mswin32|cygwin)/i)
  {
  $hsPrereq{'Win32::TieRegistry'} = 0.1;
  }
WriteMakefile(
    'NAME'		=> 'Tk::Wizard',
    'VERSION_FROM'	=> 'Wizard.pm', # finds $VERSION
    'PREREQ_PM'		=> \%hsPrereq,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Wizard.pm', # retrieve abstract from module
       AUTHOR     => 'lgoddard -at- cpan -dot- org>') : ()),
);
