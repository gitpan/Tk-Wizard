package Tk::Wizard::FileSystem;

use strict;
use warnings;
use warnings::register;

use vars '$VERSION';
$VERSION = do { my @r = ( q$Revision: 2.76 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();
use Tk::LabFrame;
use Tk::DirTree;
use Tk::Wizard::Image;

my $WINDOZE = ($^O =~ m/MSWin32/i);
my $dir_term 	 = $WINDOZE ? 'folder' : 'directory';
my $dir_term_ucf = ucfirst $dir_term;


=head1 NAME

Tk::Wizard::FileSystem - C<Tk::Wizard> pages to allow end-user filesystem access

=head1 SYNOPSIS

Currently automatically loaded by C<Tk::Wizard>, though this
behaviour is deprecated and is expected to change in 2008.

=head1 DESCRIPTION

Adds a number of methods to C<Tk::Wizard>, to allow the end-user to access
the filesystem.

=head1 METHODS

=head2 addDirSelectPage

  $wizard->addDirSelectPage ( -variable => \$chosen_dir )

Adds a page (C<Tk::Frame>) that contains a scrollable tree list of all
directories including, on Win32, logical drives.

Supply in C<-variable> a reference to a variable to set the initial
directory, and to have set with the chosen path.

Supply C<-nowarnings> with a value of C<1> to list only drives which are
accessible, thus avoiding C<Tk::DirTree> warnings on Win32 where removable
drives have no media.

Supply in C<-nowarnings> a value other than C<1> to avoid listing drives
which are both inaccessible and - on Win32 - are
either fixed drives, network drives, or RAM drives (that is types 3, 4, and
6, according to L<Win32API::File/GetDriveType>).

You may also specify the C<-title>, C<-subtitle> and C<-text> parameters, as
in L</blank_frame>.

An optional C<-background> argument is used as the background of the Entry and DirTree widgets
(default is white).

Also see L</callback_dirSelect>.

=cut

sub Tk::Wizard::addDirSelectPage {
    my $self = shift;
    my $args = {@_};
    $self->addPage( sub { $self->_page_dirSelect($args) } );
}


# PRIVATE METHOD _page_dirSelect
#
# It'd be nice to use FBox here, but it doesn't seem to support dir selection
# and DirSelect is broken and ugly
#
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -nowarnings => 1 : chdir to each drive first and only list if accessible
#             => !1: as 1, plus on types 3,4 and 6.
sub Tk::Wizard::_page_dirSelect {
    my $self = shift;
    my $args = shift;

    # print STDERR " DDD _page_dirSelect args are ", Dumper($args);
    if ( not $args->{-variable} ) {
        Carp::croak "You must supply a -variable parameter";
    }

    elsif ( not ref $args->{-variable} ) {
        Carp::croak "The -variable parameter must be a reference";
    }

    ${ $args->{-variable} } ||= '';

    # The DirTree can take a long time to read all the disk drives when
    # populating itself:
    $self->Busy;
    my $_drives = sub {
        return '/' if not $WINDOZE;
        eval('require Win32API::File');
        return Win32API::File::getLogicalDrives();
    };

    my ( $frame, @pl ) = $self->blank_frame(
        -title    => $args->{-title}    || "Please choose a $dir_term",
        -subtitle => $args->{-subtitle} || "After you have made your choice, press Next to continue.",
        -text     => $args->{-text}     || "",
        -wait     => $args->{ -wait },
    );

    # DEBUG_FRAME && $frame->configure( -background => 'light blue' );

    my $entry = $frame->Entry(
        -justify      => 'left',
        -font         => 'FIXED',
        -textvariable => $args->{-variable},
        -background => ( $args->{ -background } || 'white' ),
      )->pack(
        -side   => 'top',
        -anchor => 'w',
        -fill   => "x",
        -padx   => 15,
        -pady   => 4,
      );

    # $entry->configure( -background => $self->cget("-background") ) if $self->cget("-background");
    my $s = shift @Tk::DirTree::ISA;
    unshift @Tk::DirTree::ISA, $s if ( $s ne 'Tk::Widget' );
    my $dirsParent = $frame->Scrolled(
        "DirTree",
        -background => ( $args->{ -background } || 'white' ),
        -scrollbars => 'osoe',
        -selectbackground => "navy",
        -selectforeground => "white",
        -selectmode       => 'browse',
        -height           => 7,
        -browsecmd        => sub { ${ $args->{-variable} } = shift },
      )->pack(
        -fill   => "both",
        -padx   => 5,
        -pady   => 4,
        -expand => 1,
      );

    # $dirsParent->configure( -background => $self->cget("-background") ) if $self->cget("-background");
    my $dirs = $dirsParent->Subwidget('scrolled');

    # Add a little margin between the tree and the buttons underneath:
    $frame->Frame(
        -background => $self->{background},
        -height     => 5,
    )->pack( -side => 'top' );

    my $mkdir = $frame->Button(
        -font    => $self->{defaultFont},
        -text    => "New ".$dir_term_ucf,
        -command => sub {

            my $new_name = $self->prompt(
                -title => "Create New ".$dir_term_ucf,
                -text  => "Enter name for new $dir_term to be created in ${$args->{-variable}}"
            );
            if ($new_name) {
                $new_name =~ s/[\/\\]//g;
                $new_name = ${ $args->{-variable} } . "/$new_name";
                if ( $self->_cb_try_create_dir($new_name) ) {
                    ${ $args->{-variable} } = $new_name;
                    $dirs->configure( -directory => $new_name );
                    $dirs->chdir($new_name);
                }
            }    # if new_name

        },    # end of -command sub
      )->pack(
        -side   => 'right',
        -anchor => 'w',
        -padx   => 10,
        -ipadx  => 5,
      );

    $self->{wizardFrame}->update;
    $self->idletasks;

    if ( $self->{desktop_dir} ) {    # Thanks, Slaven Rezic.
        $frame->Button(
            -font    => $self->{defaultFont},
            -text    => "Desktop",
            -command => sub {
                ${ $args->{-variable} } = $self->{desktop_dir};

                # print STDERR " DDD   5 DirTree->configure(-directory=>$self->{desktop_dir})\n";
                $dirs->configure( -directory => $self->{desktop_dir} );
                $dirs->chdir( $self->{desktop_dir} );
            },
          )->pack(
            -side   => 'right',
            -anchor => 'w',
            -padx   => 10,
            -ipadx  => 5,
          );
    }

    foreach my $d (&$_drives) {
        # Try to prevent GUI freeze:
        $self->idletasks;
        $self->{wizardFrame}->update;
        $self->update;
        ($d) =~ /^(\w+:)/;

        if ( $args->{-nowarnings}
            and (  $args->{-nowarnings} eq "1" or not $WINDOZE )
        ) {
            $dirs->configure( -directory => $d ) if -d $d;
        }

        elsif ( $args->{-nowarnings} ) {    # Fixed drives only
            $dirs->configure( -directory => $d )
              if ( ( Win32API::File::GetDriveType($d) == 3 ) and -d $d );
        }

        else {
		   $dirs->configure( -directory => $d );
        }
    }

    # Make the user's requested directory appear as the default (?):
    $dirs->chdir( ${ $args->{-variable} } ) if ( ${ $args->{-variable} } ne '' );

    $self->Unbusy;
    return $frame;
}


sub Tk::Wizard::_cb_try_create_dir {
    my $self          = shift;
    my $dir_to_create = shift;
    my $rasError;

    File::Path::mkpath( $dir_to_create, { error => \$rasError } );

    if (@$rasError) {
        my $rh = shift @$rasError;

        # Only report the first error encountered:
        my ($sDirEntered) = keys %$rh;
        my ($sError)      = values %$rh;
        my $sMsg =
          "The $dir_term you entered ($sDirEntered) could not be created ($sError)\nPlease choose a different $dir_term.";
        $self->messageBox(
            -icon    => 'warning',
            -type    => 'ok',
            -title   => $dir_term_ucf.' Could Not Be Created',
            -message => $sMsg,
        );
        return 0;
    }

    return 1;
}



# Tk::DirTree sorts its folder list case-sensitively, but on Windows
# we want case-INsensitive search.  We roll our own until/unless the
# author of Tk::DirTree implements a fix (bug report submitted, see
# https://rt.cpan.org/Ticket/Display.html?id=28888):
REDEFINE:
{
    no warnings 'redefine';

    sub Tk::DirTree::add_to_tree {
        my ( $w, $dir, $name, $parent ) = @_;
        my $dirSortable = $WINDOZE? uc $dir : $dir;
        my $image = $w->cget('-image');

        if ( !UNIVERSAL::isa( $image, 'Tk::Image' ) ) {
            $image = $w->Getimage($image);
        }

        my $mode = 'none';
        $mode = 'open' if $w->has_subdir($dir);

        my @args = ( -image => $image, -text => $name );
        if ($parent) {                                 # Add in alphabetical order.
            foreach my $sib ( $w->infoChildren($parent) ) {
                my $sibSortable = $WINDOZE? uc $sib : $sib;
                if ( $sibSortable gt $dirSortable ) {    # added by Martin Thurn
                    push @args, ( -before => $sib );
                    last;
                }
            }
        }

        $w->add( $dir, @args );
        $w->setmode( $dir, $mode );
    }
}



=head2 callback_dirSelect

A callback to check that the directory, passed as a reference in the sole
argument, exists, or can and should be created.

Will not allow the Wizard to continue unless a directory has been chosen.
If the chosen directory does not exist, a messageBox will ask if it should be created.
If the user affirms, it is created; otherwise the user is again asked to
choose a directory.

Returns a Boolean value.

=cut

sub Tk::Wizard::callback_dirSelect {
    my $self = shift;
    my $var  = shift;
    if ( not $$var ) {
        $self->messageBox(
            '-icon'  => 'info',
            -type    => 'ok',
            -title   => 'Form Incomplete',
            -message => "Please select a $dir_term to continue."
        );
        return 0;
    }

    if ( !-d $$var ) {
        $$var =~ s|[\\]+|/|g;
        $$var =~ s|/$||g;
        my $button = $self->messageBox(
            -icon    => 'info',
            -type    => 'yesno',
            -title   => $dir_term_ucf.' does not exist',
            -message => "The $dir_term you selected does not exist.\n\n" . "Shall I create " . $$var . " ?"
        );

        if ( lc $button eq 'yes' ) {
            return $self->_cb_try_create_dir($$var);
        }

        $self->messageBox(
            -icon    => 'info',
            -type    => 'ok',
            -title   => $dir_term_ucf.' Required',
            -message => "Please select a $dir_term so that the Wizard can install the software on your machine.",
        );
        return 0;
    }

    return 1;
}


=head2 addFileSelectPage

  $wizard->addFileSelectPage(
                             -directory => 'C:/Windows/System32',
                             -variable => \$chosen_file,
                            );

Adds a page (C<Tk::Frame>) that contains a "Browse" button which pops
up a file-select dialog box.  The selected file will be displayed in a
read-only Entry widget.

Supply in C<-directory> the full path of an existing folder where the
user's search shall begin.

Supply in C<-variable> a reference to a variable to have set with the
chosen file name.

You may also specify the C<-title>, C<-subtitle> and C<-text>
parameters, as in L</blank_frame>.

An optional C<-background> argument is used as the background of the Entry widget
(default is white).

=cut

sub Tk::Wizard::addFileSelectPage {
    my $self = shift;
    my $args = {@_};
    $self->addPage( sub { $self->_page_fileSelect($args) } );
}

#
# PRIVATE _page_fileSelect
#
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -directory  => start dir
sub Tk::Wizard::_page_fileSelect {
    my $self = shift;
    my $args = shift;

    # Verify arguments:
    if ( not $args->{-variable} ) {
        Carp::croak "You must supply a -variable parameter";
    }
    elsif ( not ref $args->{-variable} ) {
        Carp::croak "The -variable parameter must be a reference";
    }
    $args->{-directory} ||= '.';
    $args->{-title}     ||= "Please choose an existing file";
    $args->{-subtitle}  ||= "After you have made your choice, click 'Next' to continue.";
    $args->{-text}      ||= '';

    # Create the mother frame:
    my ( $frame, @pl ) = $self->blank_frame(
        -title    => $args->{-title},
        -subtitle => $args->{-subtitle},
        -text     => $args->{-text},
        -wait     => $args->{ -wait },
    );

    # Put some space around the embedded elements:
    $frame->Frame(
        -background => $frame->cget("-background"),
        -width      => 10,
    )->pack(qw( -side left ));
    $frame->Frame(
        -background => $frame->cget("-background"),
        -width      => 10,
    )->pack(qw( -side right ));

	# For now (i.e. because we're lazy), don't
	# let the user type in.  They must click
	# the Browse button:
    my $entry = $frame->Entry(
        -justify      => 'right',
        -textvariable => $args->{-variable},
        -state => 'disabled',
        -background => ( $args->{ -background } || 'white' ),
	)->pack(
        -side   => 'left',
        -anchor => 'w',
        -fill   => "x",
        -expand => 1,
        -padx   => 3,
	);

    my $bBrowse = $frame->Button(
        -font    => $self->{defaultFont},
        -text    => 'Browse...',
        -command => sub {
            # getOpenFile will croak if the
            # -initialdir we give it does not
            # exist:
            my $sDirInit = $args->{-directory};
            if ( not -d $sDirInit ) {
                $sDirInit = &File::Spec::rootdir;
            }
            my $sFname = $frame->getOpenFile(
                -initialdir => $sDirInit,
                -title      => $args->{-title},
            );
            ${ $args->{-variable} } = $sFname if $sFname;
        },
    )->pack(qw( -side left -padx 3));

    return $frame;
}


=head2 addTaskListPage

Adds a page to the Wizard that will perform a series of tasks, keeping the user
informed by ticking-off a list as each task is accomplished.

Whilst the task list is being executed, both the I<Back> and I<Next> buttons
are disabled.

Parameters are as for L</blank_frame>, plus:

=over 4

=item -tasks

The tasks to perform, supplied as a reference to an array, where each
entry is a pair (i.e. a two-member list), the first of which is a text
string to display, the second a reference to code to execute.

=item -delay

The length of the delay, in milliseconds, after the page has been
displayed and before execution the task list is begun.
Default is 1000 milliseconds (1 second).
See L<Tk::after>.

=item -continue

Display the next Wizard page once the job is done: invokes the
callback of the I<Next> button at the end of the task.

=item -todo_photo

=item -doing_photo

=item -ok_photo

=item -error_photo

=item -na_photo

Optional: all L<Tk::Photo|Tk::Photo> objects, displayed as appropriate.
C<-na_photo> is displayed if the task code reference returns an undef value, otherwise:
C<-ok_photo> is displayed if the task code reference returns a true value, otherwise:
C<-error_photo> is displayed.
These have defaults taken from L<Tk::Wizard::Image|Tk::Wizard::Image>.

=item -label_frame_title

The label above the L<Tk::LabFrame|Tk::LabFrame> object which
contains the task list.  Default label is the boring C<Performing Tasks:>.

=item -frame_args

Optional: the arguments to pass in the creation of the C<Frame> object used to contain the list.

=item -frame_pack

Optional: array-refernce to pass to the C<pack> method of the C<Frame> containing the list.

=back

=head3 TASK LIST EXAMPLE

  $wizard->addTaskListPage(
    -title => "Toy example",
    -tasks => [
      "Wait five seconds" => sub { sleep 5; 1; },
      "Wait ten seconds!" => sub { sleep 10; 1; },
      ],
    );

=cut

sub Tk::Wizard::addTaskListPage {
    my $self = shift;
    my $args = {@_};

    $self->addPage( sub { $self->_page_taskList($args) } );
}

sub Tk::Wizard::_page_taskList {
    my $self = shift;
    my $args = shift;
    my @tasks;
    my @states = qw[ todo doing ok error na ];
    my $photos = {};
    foreach my $state (@states) {
        my $sArg = "-" . $state . "_photo";
        if ( !$args->{$sArg} ) {
            $photos->{$state} = $self->Photo( $state, -data => $Tk::Wizard::Image::TASK_LIST{$state} );
        }
        elsif (!-r $args->{$sArg}
            || !$self->Photo( $state, -file => $args->{$sArg} ) )
        {
            warn "# Could not read $sArg from " . $args->{$sArg};
        }
    }

    $args->{-frame_pack} = [qw/-expand 1 -fill x -padx 30 -pady 10/]
      unless $args->{-frame_pack};

    $args->{-frame_args} = [
        -background => $self->{background},
        -relief     => "flat",
        -bd         => 0,
        -label => $args->{-label_frame_title} || "Performing Tasks: ",
        -labelside => "acrosstop"
	] unless $args->{-frame_args};

    my $frame = $self->blank_frame(
        -title    => $args->{-title}    || "Performing Tasks",
        -subtitle => $args->{-subtitle} || "Please wait whilst the Wizard performs these tasks.",
        -text     => $args->{-text}     || "",
        -wait     => $args->{ -wait },
    );

    if ( $#{ $args->{-tasks} } > -1 ) {
        my $task_frame =
          $frame->LabFrame( @{ $args->{-frame_args} }, -background => $self->{background}, )
          ->pack( @{ $args->{-frame_pack} }, );

        foreach ( my $i = 0 ; $i <= $#{ $args->{-tasks} } ; $i += 2 ) {
            my $icn = "-1";
            my $p = $task_frame->Frame( -background => $self->{background}, )->pack( -side => 'top', -anchor => "w" );
            if ( exists $photos->{todo} ) {
                $icn = $p->Label(
                    -image      => "todo",
                    -anchor     => "w",
                    -background => $self->{background},
                )->pack( -side => "left" );
            }
            $p->Label(
                -font       => $self->{defaultFont},
                -text       => @{ $args->{-tasks} }[$i],
                -anchor     => "w",
                -background => $self->{background},
            )->pack( -side => "left" );
            push @tasks, [ $icn, @{ $args->{-tasks} }[ $i + 1 ] ];
        }

    }

    else {
        $args->{-delay} = 1;
    }

    if ( $args->{ -wait } ) {
        # If we got a non-zero -wait argument, we must be part of an
        # automated test.  In any case, this page is going to auto-flip to
        # the next page soon (via a call to $widget->after).  We do NOT
        # want to start executing our tasks, only to have the Wizard flip
        # to the next page while we're still executing, because then we'll
        # be trying to update Photos that no longer exist (or worse).
    }

    else {
        # Do not let the user click any buttons while we're working:
        $self->{nextButton}->configure( -state => "disabled" )
          if Tk::Exists( $self->{nextButton} );

        $self->{backButton}->configure( -state => "disabled" )
          if Tk::Exists( $self->{backButton} );

        $frame->after(
            $args->{-delay} || 1000,

            sub {
                foreach my $task (@tasks) {
                    if ( Tk::Exists( $task->[0] ) ) {
                        $task->[0]->configure( -image => "doing" );
                        $task->[0]->update;
                    }
                    my $result = &{ $task->[1] };
                    if ( Tk::Exists( $task->[0] ) ) {
                        $task->[0]->configure(
                            -image => defined($result)
                            ? $result
                                  ? 'ok'
                                  : 'error'
                            : 'na'
                        );
                        $task->[0]->update;
                    }
                }

                # We're all done, the user can click buttons again:
                $self->{backButton}->configure( -state => "normal" ) if Tk::Exists( $self->{backButton} );

                if ( Tk::Exists( $self->{nextButton} ) ) {
                    $self->{nextButton}->configure( -state => "normal" );
                    # $self->{nextButton}->invoke if $args->{ -continue };
                }
              }, # End of anonymous sub

        ); # End of $frame->after args
    }
    return $frame;
}


1;
