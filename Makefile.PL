use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::Wizard',
    'VERSION_FROM'	=> 'Wizard.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Tk			=> '0.01',
		Tk::Text	=> '0.01',
		Tk::DirTree	=> '0.01',

	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Wizard.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.org>; Daniel T Hable') : ()),
);
