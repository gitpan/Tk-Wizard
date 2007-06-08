
# $Id: 25_TaskList.t,v 1.5 2007/06/07 21:22:31 martinthurn Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;
use Tk;

my $class = 'Tk::Wizard';

BEGIN
  {
  my $mwTest;
  eval { $mwTest = Tk::MainWindow->new };
  if ( $@ ){
    plan skip_all => 'Test irrelevant without a display';
    }
  else {
    plan tests => 7;
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok('Tk');
  $class = 'Tk::Wizard';
  use_ok($class);
  } # end of BEGIN block


my $wizard = new $class( -title => "Task List Test", );
isa_ok( $wizard, $class );
isa_ok( $wizard->parent, 'Tk::MainWindow' );
ok( $wizard->addPage( sub { &page_splash($wizard) } ), 'added splash page' );
ok(
    $wizard->addTaskListPage(
        # -wait => 2,
        -continue => 2,
        -title    => "TASK LIST EXAMPLE",
        -subtitle => "task list example",
        -tasks    => [
            "This task will succeed" => \&task_good,
            "This task will fail!" => \&task_fail,
            "This task is not applicable" => \&task_na,
            "Wizard will exit as soon as this one is done" => \&task_good,
        ],
    ), 'added taskList page'
  );

$wizard->Show;
MainLoop;
pass('after MainLoop');
exit;

sub task_good {
    sleep 1;
    return 1;
}

sub task_na {
    sleep 1;
    return undef;
}

sub task_fail {
    sleep 1;
    return 0;
}

sub page_splash {
    my $wizard = shift;
    return $wizard->blank_frame(
        -wait     => 2,
        -title    => 'Task List Test',
        -subtitle => 'task list test',
        -text     => 'Task list test',
    );
}    # page_splash

__END__
