package Tk::DynaMouseWheelBind;

require Tk::Widget;
package Tk::Widget;
use strict;
use warnings;
# keep Tk::Widgets namespace clean
my($motion,
   $do_scroll,
   $mousewheel_event,
   $setup,
   );

sub DynaMouseWheelBind{
    my $w = shift;
    my @classes = @_;
    my $mw = $w->MainWindow;
    $setup->($mw);
    for my $class (@classes) {
        eval "require $class" or die $@;
        # initialize class bindings so the following changes
        # won't get overridden
        $class->InitClass($mw);
        # replace MouseWheel bindings - these should be processed
        # through the $mw binding only
        my @mw_events = ('<MouseWheel>',
                         '<4>',
                         '<5>',
                         );
        $mw->bind($class,$_,'') for (@mw_events);
        $mw->bind($class,'<<DynaMouseWheel>>',$do_scroll);
    }
}

# setup two bindings to track the window under the cursor
# and globally receive <MouseWheel>

$setup = sub{
    my $mw = shift;
    $mw->bind('all','<Motion>',$motion); # could be <Enter> as well
    $mw->bind('all','<MouseWheel>',[$mousewheel_event, Tk::Ev('D')]);
    $mw->bind('all','<4>',[$mousewheel_event, 120]);
    $mw->bind('all','<5>',[$mousewheel_event, -120]);
};

{
    my $under_cursor ;
    my $scrollable;
    my $delta;

    $motion = sub {
        $under_cursor = $_[0]->XEvent->Info('W');
    };

    $do_scroll = sub{
        $scrollable->yview('scroll',
                             -($delta/120)*3,
                             'units');
    };

    $mousewheel_event = sub{
        my $widget = shift;
        $delta = shift;
        # just in case, the mouse has not been moved yet:
        my $w = $under_cursor ||= $widget;
        my @tags = $w->bindtags;
        my $has_binding;
        until ($has_binding || $w->isa('Tk::Toplevel')){
            if($w->Tk::bind(ref($w),'<<DynaMouseWheel>>')){
                $has_binding = 1 ;
            }else{
                $w = $w->parent;
            }
        }
        if ($has_binding) {
            $scrollable = $w;
            $w->eventGenerate('<<DynaMouseWheel>>');
        }
    };
} # end of scope for $under_cursor, $scrollable, $delta

1;