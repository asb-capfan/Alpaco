#!/usr/bin/perl 
                            
# Alpaco_helper.pl    
#                                                
# This program was made to prepare text for Alpaco.  
# It will seperate sequences by a space, and
# will give the ability to save/edit a file. This 
# tool can also be used as a very basic text editor.
# 
#       
# Copyright (C) 2002
# Ted Pedersen, University of Minnesota, Duluth
# tpederse@d.umn.edu
# Brian Rassier, University of Minnesota, Duluth
# rass0028@d.umn.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#-----------------------------------------------------------------------------
#                              Start of program
#-----------------------------------------------------------------------------

# use custom lib folder
use lib './lib';                                    

use Tk;
use Tk::Markdown;
use Tk::DynaMouseWheelBind;

#Loads the SimpleFileSelect module if possible, otherwise defaults to a label
$SimpleFileSelect = "Label";
eval{
    require Tk::SimpleFileSelect;
    $SimpleFileSelect = "SimpleFileSelect";
};
########## MAKES THE INTERFACE & WIDGETS #################
$mw = MainWindow->new;
$mw->title("Alpaco Text Preparation");

# set up auto scroll binding to mouse wheel
$mw->DynaMouseWheelBind('Tk::Markdown', 'Tk::Text', 'Tk::Canvas');

#frame for entry and labels
$frame_w = $mw->Frame->pack(-side,'top',-fill,'x');
#frame for the menu 
$frametop = $frame_w->Frame->pack(-side,'top',-fill,'x');
#label for the entry widget
$frame_w->Label(-text,"Filename:")->pack(-side,'left',-anchor,'w');
#entry widget
$entry_w = $frame_w->Entry(-textvariable,\$filename,-background,'white',
			   -width,25)->pack(-side,'left',
					    -anchor,'w');


#makes the file menu
$frametop->Menubutton(-text,"File",			   
			 -menuitems,[['command',"Open Text File",-command,\&load_file],		  
				     ['command',"Find Text Files",-command,\&find],
				     ['command',"Save File",-command,\&save_file],
				     "-",
				     ['command',"Clear Screen",-command,\&clear_window],			     
				     "-",				     
				     ['command',"Exit",-command,
				      sub{ #removes the temporary files that were made if present
                        if( -e 'undo_temp' and -f 'undo_temp' ) {
                            unlink('undo_temp');
                        }
					  exit;}]],						
		      -tearoff,0)->pack(-side,'left',-anchor,'w');

#makes the options menu
$frametop->Menubutton(-text,"Options",	 
		       -menuitems,[['command',"Split Up Tokens",-command,\&split_file],
				   ['command',"Undo Split - Only available once",-command,\&undo_split]],
		      -tearoff,0)->pack(-side,'left',-anchor,'w');


#makes the help menu
$frametop->Menubutton(-text,"Help",  
		      -menuitems,[['command',"Help",-command,\&help_pop]],	
		      -tearoff,0)->pack(-side,'left',-anchor,'w');


#exit button
$frame_w->Button(-text,"Exit", -command,
		 sub{    #removes the temporary files that were made if present
                if( -e 'undo_temp' and -f 'undo_temp' ) {
                    unlink('undo_temp');
                }
		     exit;},
		 -activebackground,"blue",
		 -background,"black",
		 -foreground,"white")->pack(-side,'right');


#informational label button
$mw->Label(-textvariable,\$info,-relief,'ridge')->pack(-side,'bottom',
						       -fill,'x');
#scrolled text window widget
$text_w = $mw->Scrolled("Text",-background,"white")->pack(-side,'bottom',
							     -fill,'both',
							     -expand,1);


#HOT KEY BINDINGS
#define enter callback for entry one
$entry_w->bind("<Return>",\&load_file);
#Control + s saves
$mw->bind("<Control-Key-s>", \&save_file);
#Control + c clears 
$mw->bind("<Control-Key-c>", \&clear_window);

#gives the entry button the keyboard focus to start
$entry_w->focus();

#runs the loop for the GUI						     
MainLoop;


######################## FUNCTIONS FOR CALLBACKS ##############################  

#load_file, it loads the file from the entry widget if possible
sub load_file {
    $info = "loading file '$filename'";

    #clear out the text widget if necessary
    $text_w->delete("1.0","end");

    #open the file
    if(!open(FILE, "$filename")){
	$text_w->insert("end","ERROR: Could not open '$filename'\n");
	$info = "Error loading '$filename'";
	return;
    }
    
    #store the file that was loaded
    $keepfile = $filename;

    #insert the file into the text widget
    while(<FILE>) {
	$text_w->insert("end",$_);
    }

    close(FILE);
    $info = "File '$filename' loaded";
}


#save_file, it saves the file to the name in the entry widget
sub save_file {
    $info = "Saving '$filename'";



    #makes a toplevel widget with entry widget and save/cancel buttons
    $t1 = $mw->Toplevel();    
    #withdraw to use a different popup method
    $t1->withdraw();    
    $t1->title("Save File");
    $t1->Label(-text,"Save Filename:")->pack(-side,'top');
    $e = $t1->Entry(-textvariable,\$save,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    $t1->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t1->withdraw})->pack(-side,'bottom');
    $b = $t1->Button(-text,"Save",-background,"black",-foreground,"white",-command,\&save2)->pack(-side,'bottom');
    #define enter callback for entry one
    $e->bind("<Return>",\&save2);        
    #makes the pop-up button appear
    $t1->Popup;    
    $t1->focus();
    #gives the entry widget the keyboard focus to start with    
    $e->focus();
}


#This function makes a pop-up if users try to save over a file that 
#already exists
sub file_exists{
    #get the file that was passed in as a parameter
    my $the_file = shift;

    #makes a toplevel widget with entry widget and save/cancel buttons
    $exists_pop = $mw->Toplevel();
    #withdraw to use a different popup method
    $exists_pop->withdraw();
    $exists_pop->title("Save over file?");
    $exists_pop->Label(-text,"$the_file already exists.  Continue and save over it?")->pack(-side,'top');

    $exists_pop->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$exists_pop->withdraw; $OK = 0; return;})->pack(-side,'bottom');
    $exists_pop->Button(-text,"OK",-background,"black",-foreground,"white",-command,sub{$exists_pop->withdraw; $OK = 1; return;})->pack(-side,'bottom');
    
    #makes the pop-up button appear
    $exists_pop->Popup;
    $exists_pop->focus();

	}	    
#-----------------------------------------------------------------------------
#file_exists end


#subfunction that is called if a file is to be saved-called by save_pop and others
sub save2{        
    #error checking to check for files    
    if(!$save){
	$info = "Error: Please enter a filename to save to";	
	$entry_w->bell();
	return(-1);    }    

    #THIS SECTION CHECKS IF A FILE EXISTS BEFORE SAVING OVER IT.
    #make $OK not 0 or 1, to see what it gets set at with the 
    #file_exists function
    $OK = "256";

    #if the $save file already exists, call file_exists pop-up
    if(-e $save){
	file_exists($save);
    }
    #if the $save file already exists, then wait until the $OK variable
    #gets changed.  This variable gets changed to a 0 or 1 depending on
    #if the user chose cancel or OK to saving over the existing file
    if(-e $save){
	$entry_w->waitVariable(\$OK);
    }

    #if $OK equals 0, that means the user does not want to save over
    #the existing file, so return.
    if($OK == 0){
	return;
    }


    #error checking when opeining the file to save to
    if(!open(FH, ">$save")){	
	$info = "Error loading '$save'";
	$entry_w->bell();	
	return(-1);    }

    #print the text widget to the file
    print FH $text_w->get("1.0", "end");
    
    close(FH);

    #remove pop-up
    $t1->withdraw if(Exists($t1));
    $info = "Save Complete.";
}


#clear_window, it just clears the text window, and the entry window
sub clear_window {
    #removes the text from the text widget
    $text_w->delete("1.0","end");

    #removes the entry from the entry widget
    $entry_w->delete("0","end");

    $info = "Screen Cleared";
}



#save_file, it saves the file to the name in the entry widget
sub split_file {

    #makes a toplevel widget with entry widget and save/cancel buttons
    $t2 = $mw->Toplevel();    
    #withdraw to use a different popup method
    $t2->withdraw();    
    $t2->title("Split File");
    $t2->Label(-text,"A token is naturally considered a sequence of non-space characters.\nIf you want to redefine this, and consider new sequences as tokens, enter the sequences here. \nPlease separate tokens by spaces: \neg{! ? .} will make punctuation seperate tokens. \nA default split rule is given.  Change this rule as desired.")->pack(-side,'top');
    $e2 = $t2->Entry(-textvariable,\$splits,-background,"white",-takefocus,1)->pack(-side,'top',
										    -anchor,'w',
										    -fill,'x',
										    -expand,1);
    $t2->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t2->withdraw})->pack(-side,'bottom');
    $b2 = $t2->Button(-text,"Split",-background,"black",-foreground,"white",-command,\&splitter)->pack(-side,'bottom');
    #define enter callback for entry one
    $e2->bind("<Return>",\&splitter);        
    #makes the pop-up button appear
    $t2->Popup;    
    $t2->focus();
    #gives the entry widget the keyboard focus to start with    
    $e2->focus();
    
    #set the default split rule if necessary
    $splits = "? ! . , ' \" - : " if($splits eq ""); 
}

#subfunction that is called if a file is to be split up
sub splitter{        
    #error checking to check for files    
    if(!$splits){
	$info = "Error: Please enter a characters to seperate";	
	$entry_w->bell();
	return(-1);    }   

    #error checking when opeining the file to save to for undo function
    if(!open(FH, ">undo_temp")){	
	$info = "Error opening 'undo_temp'";
	$entry_w->bell();	
	return(-1);    
    }

    #puts the splitting characters into an array
    @temp = split / /, $splits;

    $i = 1;
    while($text_w->compare("$i.0", "<", "end")){
	#gets the next line from the text widget
	$line = $text_w->get("$i.0", "$i.0 lineend");

	#prints the linie to a temp file for undo ability
	print FH $line."\n";

	#for each splitting character
	foreach (@temp){
	    #must hard code some of the more commonly split items that are metasymbols
	    #if in a variable, they can't be deliminated
	    if($_ =~ /\./){
		$line =~ s/\./ $& /g;
		next;
	    }

	    if($_ =~ /\?/){
		$line =~ s/\?/ $& /g;
		next;
	    }

	    if($_ =~ /\+/){
		$line =~ s/\+/ $& /g;
		next;
	    }

	    if($_ =~ /\*/){
		$line =~ s/\*/ $& /g;
		next;
	    }

	    if($_ =~ /\^/){
		$line =~ s/\^/ $& /g;
		next;
	    }

	    if($_ =~ /\$/){
		$line =~ s/\$/ $& /g;
		next;
	    }

	    if($_ =~ /\(/){
		$line =~ s/\(/ $& /g;
		next;
	    }

	    if($_ =~ /\)/){
		$line =~ s/\)/ $& /g;
		next;
	    }

	    if($_ =~ /\{/){
		$line =~ s/\{/ $& /g;
		next;
	    }

	    if($_ =~ /\}/){
		$line =~ s/\}/ $& /g;
		next;
	    }

	    if($_ =~ /\[/){
		$line =~ s/\[/ $& /g;
		next;
	    }

	    if($_ =~ /\]/){
		$line =~ s/\]/ $& /g;
		next;
	    }

	    if($_ =~ /\|/){
		$line =~ s/\|/ $& /g;
		next;
	    }
	    
	    if($_ =~ /\\/){
		$line =~ s/\\/ $& /g;
		next;
	    }
	    
	    $line =~ s/($_)/ $& /g;
	}

	#delete old line, insert the new line
	$text_w->delete("$i.0", "$i.0 lineend");
	$text_w->insert("$i.0",$line);
	$i++;
    }

    close(FH);

    #remove the pop-up
    $t2->withdraw if(Exists($t2));
    $info = "Split Complete.";
}

sub undo_split{

    #error checking when opeining the file to open for undo function
    if(!open(FILE, "undo_temp")){	
	$info = "No undo found";
	$entry_w->bell();	
	return(-1);    
    }

    #clear out the text widget if necessary
    $text_w->delete("1.0","end");

    #insert the file into the text widget
    while(<FILE>) {
	$text_w->insert("end",$_);
    }

    close(FILE);

    $info = "Split Undone";
}


sub help_pop{

 #make a toplevel widget
    my $t3 = $mw->Toplevel();
    #withdraw to use a different pop-up method
    $t3->withdraw;
    $t3->title("Help");
    $f = $t3->Frame->pack(-side,'bottom');
    $help = $t3->Scrolled("Markdown",
        -scrollbars => 'soe',
        -background =>'white',
        -selectbackground =>'blue',
        -selectforeground => 'white',
    )->pack(-expand, 1, -fill,'both');
    
    
    #error checking for opening the README file
    
    my $help_filename = 'README.md';
    open(my $fh, '<:encoding(UTF-8)', $help_filename);
    if(!$fh) {
        $info = "Error loading '$help_filename'";
        $t3->withdraw;
        $entry_w->bell();
        return(-1);
    }

    #inserts the README into the text file
    my $help_content = '';
    while(my $row = <$fh>){
        $help_content .= $row;
    }
    close($fh);
    $help->insert("end",$help_content);

    #disables the text widget for read-only access
    $help->configure(-state,'disabled');    
    
    #makes a button to close the window
    $f->Button(-text,"Close",-background,"black",-foreground,"white",-command,sub{$t3->withdraw})->pack(-side,'bottom',
													-expand,1,
													-fill,'x');
   
    #makes the pop-up button appear
    $t3->Popup;
    $t3->focus();

    #make text widget able to write to
    $help->configure(-state,'normal');

    #select the pertinent info
    $help->tagAdd("MySel","626.0","651.0 lineend");

    #moves to the right spot in the text widget		       	  
    $help->see("MySel.first");
    $help->configure(-state,'disabled');


}

sub find{
  #make a SimpleFileSelect widget
    $top = $mw->$SimpleFileSelect();

    #save the selected file in $file
    if($top->can('Show')){
	$file = $top->Show;
    }
    #if SimpleFileSelect is not installed, attempt to let the user know
    else{
	#make a toplevel widget
	$t9 = $mw->Toplevel();
	$top2 = $t9->Label(-text,"SimpleFileSelect module not installed.\nFind option not available.");
	$top2->pack;
	$t9->Button(-text,"Close",-command,sub{$t9->withdraw;})->pack();
	return;
    }

    #put $file into the entry widget
    $filename = $file;

    #load the file
    &load_file;


}

__END__



=head1 NAME

alpaco_helper.pl 

=head1 SYNOPSIS

perl alpaco_helper.pl

=head1 DESCRIPTION

Alpaco is a program that is designed to align bilingual parallel texts.
Alpaco considers tokens as anything separated by a space in the input file, 
and many times the text is not prepared this way.  Many corpora alignments 
need to have punctuation and other sequences to be considered their own 
tokens, and the text may not have spaces to separate these sequences.  This 
is where Alpaco_Helper.pl comes in.  It is a simple text editor that can open
files, and separate different sequences of characters given by the user.  It 
will separate the character sequences by a space, then the user can save the 
file as desired.  This way the text is prepared to load into Alpaco, and 
aligned how the user desires.
 

=head1 AUTHOR

Alpaco and Alpaco_helper were written by Brian Rassier <rass0028@d.umn.edu> 
as a research project for Dr. Ted Pedersen <tpederse@d.umn.edu>


=head1 SEE ALSO

For information about general Alpaco usage please see the README that was 
distributed with the Alpaco package.

=cut
