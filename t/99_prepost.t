#!/usr/bin/perl -w

use strict;
use ExtUtils::testlib;
use Test::More;
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
    plan tests => 33;
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk::Wizard');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.6 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my @out;
my $Wait = 1000;


foreach my $style (qw[ top 95 ]) {
    my $wizard = Tk::Wizard->new(
        -debug => undef,
        -style => $style,
    );
    isa_ok( $wizard, 'Tk::Wizard');
    ok(
        $wizard->configure(
            -preNextButtonAction   => sub { &preNextButtonAction($wizard) },
            -postNextButtonAction  => sub { &postNextButtonAction($wizard) },
            -preFinishButtonAction => sub { &postNextButtonAction($wizard) },
            -finishButtonAction    => sub { &postNextButtonAction($wizard) },
        )
    );
    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page 1",
                    -wait  => $Wait,
                );
            }
        )
    );
    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page 2",
                    -wait  => $Wait,
                    -width => 300,
                );
            }
        )
    );
    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page 3",
                    -wait  => $Wait,
                    -width => 900,
                );
            }
        )
    );
    ok(
        $wizard->addPage(
            sub {
                $wizard->blank_frame(
                    -title => "page last",
                    -wait  => $Wait,
                );
            }
        )
    );
    $wizard->Show;
    MainLoop;
    pass;
}    # foreach

sub preNextButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "pre next button on page $_";

    # diag $out[-1];
    pass;
    return 1;
}    # preNextButtonAction

sub postNextButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "post next button on page $_";

    # diag $out[-1];
    pass;
    return 1;
}    # postNextButtonAction

sub preFinishButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "pre finish button on page $_";

    # diag $out[-1];
    pass;
    return 1;
}    # preFinishButtonAction

sub finishButtonAction {
    my $wizard = shift;
    $_ = $wizard->currentPage;
    push @out, "finish button on page $_";

    # diag $out[-1];
    pass;
    return 1;
}    # finishButtonAction

__END__

