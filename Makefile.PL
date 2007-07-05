
# $Id: Makefile.PL,v 2.13 2007/07/05 00:24:24 martinthurn Exp $

use inc::Module::Install;

name('Tk-Wizard');
abstract('GUI for step-by-step interactive logical process');
version(2.011);
author('cpan-at-lgoddard-dot-net & mthurn@cpan.org');
license('perl');

requires("Carp");
requires("Cwd");
test_requires("ExtUtils::testlib");
requires("File::Copy");
requires("File::Path");
requires("File::Spec");
test_requires("FileHandle");
test_requires("Test::More");
requires('Tk');
requires("Tk::After");
requires("Tk::DialogBox");
requires("Tk::DirTree");
requires("Tk::ErrorDialog");
requires("Tk::Frame");
requires("Tk::LabFrame");
requires("Tk::MainWindow");
requires("Tk::ProgressBar");
requires("Tk::ROText");

if ($^O =~ m/win/i)
  {
  requires('Win32::Shortcut');
  requires('Win32::TieRegistry');

  eval 'require Win32;';
  if (! $@)
    {
    eval '$_ = $Win32::VERSION;';
    if (! $@ && ($_ < 0.2))
      {
      requires('Win32::OLE');
      warn "Win32.pm version is $_ (less than 0.2), therefore we will use Win32::OLE.  (This requires Windows Scripting Host which is present on Win98 and higher.)\n";
      }
    else
      {
      warn "Using Win32 for special folders...\n";
      requires('Win32' => 0.2);
      }
    }
  else
    {
    die "There appears to be something wrong with your Perl installation. You are on a Windows platform without the core Win32 module. You can still use this module, but parts you will not be able to create shortcuts to the windows special folders.";
    }
  } # if MSWin32

WriteAll;

__END__
