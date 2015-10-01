#!/usr/local/bin/perl 

# alpaco.pl
# Program to take paralell texts in 2 languages and allow a user
# to manually align the words/phrases.
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

#allows the use of Tk
use Tk;
use Tk::Markdown;
use Tk::DynaMouseWheelBind;

#this loads the HistEntry module if possible, otherwise just uses regular entry widgets
$Entry = "HistEntry";
eval {
    #try loading the module, otherwise $Entry is left to the value "Entry"
    require Tk::HistEntry;
    $Entry = "HistEntry";
};


#Loads the SimpleFileSelect module if possible, otherwise defaults to a label
$SimpleFileSelect = "Label";
eval{
    require Tk::SimpleFileSelect;
    $SimpleFileSelect = "SimpleFileSelect";
};


#needed for the floor function, used to interpret Blinker files
use POSIX qw(ceil floor);

#-----------------------------------------------------------------------------
#MAKE THE INTERFACE/WIDGETS 
#-----------------------------------------------------------------------------

#These are the colors for the word buttons.  They can be changed here, then they are
#changed throughout the code.  
$normal = "light gray";
$connected = "light blue";
$nullback = "black";
$nullfore = "orange";



#for indexes in my checkbutton widget arrays
$size1 = $size2 = $active1 = $active2 = 0;

#set these variables to Blinker as Default
$v = 10; #verses per file
$sam = 25; #samples of files
$an = 7; #annotators


#set flag for resizing to -1
$bopenflag = -1;

#set $blinkfile to "" so we can tell if there has been a blinker file opened
$blinkfile = "";

my $mw = MainWindow->new(-height,550,-width,660);
$mw->packPropagate(0);
$mw->title("Aligner for Parallel Corpora (Alpaco)");
#$mw->geometry("550x550");

# set up auto scroll binding to mouse wheel
$mw->DynaMouseWheelBind('Tk::Markdown', 'Tk::Text', 'Tk::Canvas');

#frame for entry and labels
$frametop = $mw->Frame->pack(-side,'top',-fill,'x');

#frame for canvas widget
$frameleft = $mw->Frame->pack(-side,'left',-fill,'y');

#frame for main buttons
$frameright = $frameleft->Frame->pack(-side,'right',-fill,'y');

#frame for menus
$frametoptop = $frametop->Frame->pack(-side,'top',-fill,'x');
$frametopbottom = $frametoptop->Frame->pack(-side,'bottom',-fill,'x');
#informational label button
$frametoptop->Label(-textvariable,\$info,-relief,'ridge',-width,70)->pack(-side,'right',
									  -fill,'x');
#label for entry1
$frametop->Label(-text,"Source File:")->pack(-side,'left',-anchor,'w');

#entry widget 1
$entry1_w = $frametop->$Entry(-textvariable,\$file1,
				 -background,"white",
				 -takefocus,1)->pack(-side,'left',
						     -anchor,'w');

#starts the cursor at the entry1 widget
$entry1_w->focus();

#label for entry2
$frametop->Label(-text,"Target File:")->pack(-side,'left',-anchor,'w');

#entry widget 2
$entry2_w = $frametop->$Entry(-textvariable,\$file2,
			     -background,"white")->pack(-side,'left',
							-anchor,'w');

#checkbutton for line by line
$cb = $frametop->Checkbutton(-text,'Line-By-Line',-variable,\$cb_value,-relief,'ridge',
			     -command,\&lbyl)->pack(-side,'left');

#button for line-by-line, don't pack it until line-by-line is on
$nl = $frametopbottom->Button(-text,'Next Line',-command,\&load_files);
$pl = $frametopbottom->Button(-text,'Prev Line',
			-command,sub{
			    #decrement the line number, then load the files
			    $linenum = $linenum - 2;
			    $linenum2 = $linenum2 - 2;
			    &load_files});
##########MENUS##########
#makes the file menu
$frametoptop->Menubutton(-text,"File",			   
			 -menuitems,[
				     #This option is pretty silly. It just simulates pressing the enter key for each entry field.  I commented it out to try alpaco without it.
				     #['command',"Open Text Files",-command,\&load_files],
				     ['command',"Find Text Files",-command,\&find],
				     "-",
				     ['command',"Save Current Work to File",-command,\&save_blink],
				     "-",
				     ['command',"Open an Alpaco File",-command,\&open_pop],
				     ['command',"Save an Alpaco File",-command,\&save_pop],
				     "-",
				     ['command',"Clear Connections",-command,\&clear_lines],
				     ['command',"Clear All",-command,\&clear_tot],				     
				     "-",
				     ['command',"Exit",-command,sub{
					 #removes the temporary files that were made if present
					 system("rm Blinktemp1 Blinktemp2") if(open(FP1,"Blinktemp1"));
					 system("rm sizetemp SizeVerse1 SizeVerse2") if(open(FP1,"sizetemp"));
					 exit;}]],			
			 -tearoff,0)->pack(-side,'left',
					   -anchor,'w');

#makes the options menu
$frametoptop->Menubutton(-text,"Options",
			 -menuitems,[['command',"Connect",-command,\&con],
				     ['command',"Null Connect",-command,\&nullcon],
				     ['command',"Undo Connection",-command,\&undo],
				     ['command',"Redraw Connect",-command,\&redo],  
				     "-",
				     ['command',"View Sentences",-command,\&show_sentences], 
				     ['command',"Change Mode",-command,\&chmode], 
				     ['command',"Change Data Limits",-command,\&data_pop]],
			 -tearoff,0)->pack(-side,'left',
					   -anchor,'w');

#makes the help menu widget
$frametoptop->Menubutton(-text,"Help",
			 -menuitems,[['command',"Help",-command,\&help_pop],
				     ['command',"Keyboard Shortcuts",-command,\&kbd_pop],
				     ['command',"About",-command,\&about_pop]],
			 -tearoff,0)->pack(-side,'left',
					   -anchor,'w');

##########MENUS END##########


##########MAIN BUTTONS##########
#connect button
$frametopbottom->Button(-text,"Connect", -command,\&con,
			-background,$connected,
			-activebackground,'blue'
			)->pack(-side,'left',-anchor,'w',-fill,'x');
#null connect button
$frametopbottom->Button(-text,"Null Connect", -command,\&nullcon,
			-activebackground,"blue",
			-background,$nullback,
			-foreground,$nullfore)->pack(-side,'left',-anchor,'w',-fill,'x');
#undo button 
$frametopbottom->Button(-text,"Undo", -command,\&undo,
			-activebackground,"blue"
			)->pack(-side,'left',-anchor,'w',-fill,'x');
#redo button
$frametopbottom->Button(-text,"Redraw (one line)", -command,\&redo,
			-activebackground,"blue"
			)->pack(-side,'left',-anchor,'w',-fill,'x');
##########MAIN BUTTONS END##########


##########SIZING OPTION##########
#makes a frame for the sizing option
$sizeframe = $frameright->Frame->pack(-fill,'x');

#makes the space shrinking button
$minus = $sizeframe->Button(-text,"   -   ",-command,sub{$minus->focus();
						       &resize;},
			    -activebackground,"blue",
			    #-background,"dark green",
			    #-foreground,"white",
			    -takefocus,1,
			    )->pack(-side,'left',-anchor,'w',-pady,5);

#makes the label for the word distance
$sizeframe->Label(-text," Resize ",-relief,'ridge')->pack(-side,'left',-anchor,'w');

#makes the space enlarging button
$plus = $sizeframe->Button(-text,"   +   ",-command,sub{$plus->focus();
						      &resize;},
			   -activebackground,"blue",
			   #-background,"dark green",
			   #-foreground,"white",
			   -takefocus,1
			   )->pack(-side,'left',-anchor,'w',-pady,5);
##########SIZING OPTION END##########


##########NEXT/PREV BLINKER OPTION##########
#makes a frame for the next/previous buttons
$nextframe = $frameright->Frame->pack(-fill,'x');

#prev button
$prev = $nextframe->Button(-text,"<Prev", -command,sub{$prev->focus;&next},
			   -activebackground,"blue",
			   #-background,"dark green",
			   #-foreground,"white"
			   );


#next button
$next = $nextframe->Button(-text,"Next>", -command,sub{$next->focus;&next},
			   -activebackground,"blue",
			   #-background,"dark green",
			   #-foreground,"white"
			   );
##########NEXT/PREV BLINKER OPTION END##########


##########NEXT/PREV BLINKER ANNOTATOR OPTION##########
#makes a frame for the next/previous buttons for annotator
$nextanframe = $frameright->Frame->pack(-fill,'x');

#prev button
$prevan = $nextanframe->Button(-text," <-- ", -command,sub{$prevan->focus;&nextan},
			       -activebackground,"blue",
			       #-background,"dark green",
			       #-foreground,"white"
			       );
#next button
$nextan = $nextanframe->Button(-text," --> ", -command,sub{$nextan->focus;&nextan},
			       -activebackground,"blue",
			       #-background,"dark green",
			       #-foreground,"white"
			       );
##########NEXT/PREV BLINKER ANNOTATOR OPTION END##########


##########BROWSE/EDITR OPTION##########
#makes a frame for the radio buttons
$radioframe = $frameright->Frame->pack(-fill,'x');

#makes the browse/edit checkbuttons and stores their IDs
push @rb,$radioframe->Radiobutton(-text,'Browse',-value,'Browse',-variable,\$rb_value,
				  -background,'black',-foreground,'white',
				  -command,\&browse,-indicatoron,0);
push @rb,$radioframe->Radiobutton(-text,'Edit',-value,'Edit',-variable,\$rb_value,
				  -background,'black',-foreground,'white',
				  -command,\&browse,-indicatoron,0);
#draws the widgets
$rb[0]->pack(-side,'left',-padx,5,-pady,5);
$radioframe->Label(-text,"  Mode  ",-relief,'ridge')->pack(-side,'left',-anchor,'w');
$rb[1]->pack(-side,'left',-padx,5,-pady,5);

#invokes the browse button as a default
$rb[0]->invoke;
##########BROWSE/EDITR OPTION END##########

#exit button
$frameright->Button(-text,"Exit", -command,sub{
    #removes the temporary files that were made if present
    system("rm Blinktemp1 Blinktemp2") if(open(FP1,"Blinktemp1"));
    system("rm sizetemp SizeVerse1 SizeVerse2") if(open(FP2,"sizetemp"));
    exit;},
		    -activebackground,"blue"
		    )->pack(-side,'top',-anchor,'w',-fill,'x',-pady,10);

#View Sentences button
#$frameright->Button(-text,"View Sentences", -command,\&show_sentences,
#		    -activebackground,"blue"
#		    )->pack(-side,'top',-anchor,'w',-fill,'x',pady,10);

#makes the canvas widget, with a parent for binding reasons
$parentcanvas = $frameleft->Scrolled("Canvas",-background,
				     'white',-takefocus,1,-width,500)->pack(-side,'bottom',
									    -fill,'both',-expand,1);
$canvas = $parentcanvas->Subwidget("canvas");


#adds a buffer in the top of the canvas
$canvas->createText(30,30,-text," ");

##########binding keyboard shortcuts############
#define enter callback for entry one
$entry1_w->bind("<Return>",\&load_1);

#define enter callback for entry one
$entry2_w->bind("<Return>",\&load_2);

#Control + s saves
$mw->bind("<Control-Key-s>", \&save_pop);

#control + o opens
$mw->bind("<Control-Key-o>", \&open_pop);

#Contryl + c quits
$mw->bind("<Control-Key-c>", \&con);

#binds Ctrl + n to null connect 
$mw->bind("<Control-Key-n>",\&nullcon);

#binds Ctrl + c to connect when in list widgets
$mw->bind("<Button-3>",\&con);

#binds u to undo function when in list widgets
$mw->bind("<Control-Key-u>",\&undo);

$mw->bind("<Control-Key-r>",\&redo);

##########binding keyboard shortcuts end############

#sets the buffer between widgets (words) in the canvas
$buff = 30;

#Start the main loop
MainLoop;

#-----------------------------------------------------------------------------
#Sub-routines
#-----------------------------------------------------------------------------


#function that loads both files if the menu item is pressed.  
#This function uses a sequence of flags from return values of the load_1 and load_2
#functions, in order to reuse code.
sub load_files{
    #set variables to 0
    $flag = $t1 = 0;

    #load source file, get return value
    $t1 =  &load_1;

    #set the flag if source file had errors
    $flag = 1 if $t1 < 0;
    $t1 = 0;
    $t1 = &load_2;

    #set the flag if target file had errors
    $flag += 2 if $t1 < 0;

    #check the results and let the user know if there were errors
    $info = "Error opening file 1" if $flag eq 1;
    $info = "Error opening file 2" if $flag eq 2;
    $info = "Error opening file 1 and 2" if $flag eq 3;
    $info = "Files Loaded" if $flag eq 0;
    
    #set the scroll region now that items have been inserted
    $canvas->configure(-scrollregion,[ $canvas->bbox("all") ]);
}
#-----------------------------------------------------------------------------
#load_files end


#function that loads the source file into the tool
sub load_1{
    #enables the flag for the size option
    $bopenflag = 0;

    $info = "opening file '$file1'...";
    
    #store file to see if a new one was entered
    $holdfileold = $holdfile;
    $holdfileold = "" if(!$holdfile);
    $holdfile = $file1 unless($file1 eq "SizeVerse1");

    #error checking for opening file 1
    if(!open(FILE, "$file1")){
	$info = "Error opening '$file1'";
	$entry1_w->bell();
	return(-1);
    }
    
    #clear out the old sentence
    undef $sentence1;

    #clears the previous connections
    &clear_lines;

    #remove the old words from the canvas
    while(@del1){
	$canvas->delete(pop @del1);
    }

    #clear the id's from the past file
    undef @del1;

    #clears the canvas text for file 1
    while(@id1){
	$d = (pop @id1);
	$d->destroy();
    }
    
    #undefines the id's for file 1
    undef @id1;

    #reset the status array for list 1
    $size1 = $active1 = 0;
    undef @status1;


#This if statement takes care of the line-by-line loading if necessary
    if($cb_value){
	#reset the line number if a new file was loaded
	$linenum = 0 unless($holdfileold eq $holdfile);
	$linenum = 0 if($linenum < 0);

	#load the next line
	for my $i (0..$linenum){
	    $line = <FILE>;
	}
	#check if there were any lines left, let the user know
	if(!$line){
	    $info = "No more lines in the file";
	    $linenum = 0;
	    return;
	}
	close (FILE);

	#add the file to the history if that module is present
	$entry1_w->historyAdd($file1) if($entry1_w->can('historyAdd'));

	#set the yvaraiable to the proper screen distance
	my $yvar = 50;
	
	#keep the sentence for viewing later
	$sentence1 = $line;
	
	#parse the line  
	$line =~ s/[^\S ]//g;    #remove all whitespace except spaces
	$line =~ s/  +/ /g;   #remove multiple spaces

	#puts the line into an array for processing
	my @temp = split / /, $line;

	#process the line word-by-word
	foreach my $word (@temp){
	    #make word labels
	    $word = " " x (10-length($word)) . $word;
	    my $label1 = $canvas->Checkbutton(-text,$word,-relief,'ridge',-justify,'right',-takefocus,1,
					      -selectcolor,'blue',-indicatoron,0,-variable,\$status1[$size1++],
					      -disabledforeground,'blue',-activebackground,'dark green',
					      -activeforeground,'white');
	    
	    #keep track of $id for configuring the checkbuttons
	    push @id1,$label1;

	    #keep track of the actual object to delete it later
	    push @del1,$canvas->createWindow(150,$yvar,-anchor,'e',-window,$label1);

	    #increment the $yvar for the next object to insert
	    $yvar += $buff;    
	}    
	#change the scroll region because more objects were added
	$canvas->configure(-scrollregion,[ $canvas->bbox("all") ]);

	close(FILE);

	#update informational label for user knowledge
	$info = "Line $linenum from file '$file1' loaded";

	#increment the line number
	$linenum++;

	#make sure the words are enabled/disabled as needed
	&browse;

	#do not continue loading, because line-by-line is finished
	return;
    }	
	
    #This section is executed on a regular loading of a file (not line-by-line)

    #save filename for save function, to print to a savefile in case
    #the user changes the entry1 widget entry.
    $entry1_w->historyAdd($file1) if($entry1_w->can('historyAdd'));
    $keepfile1 = $file1;
	
    #set $yvar to 50 for inserting position
    my $yvar = 50;
    
    #This while loop seperates the words in the file, makes widgets for
    #each word, and inserts them into the canvas. It also makes the null widgets.
    while(<FILE>) {
	
	#keep the sentence for viewing later
	$sentence1 = $sentence1 . $_;
	
	#parse the file
	$_ =~ s/[^\S ]//g;    #remove all whitespace except spaces
	$_ =~ s/  +/ /g;      #remove multiple spaces
	
	#split up the line into an array
	my @temp = split / /, $_;

	#process the line word-by-word
	foreach $word (@temp){
	    #make word labels
	    my $word = " " x (10-length($word)) . $word;
	    my $label1 = $canvas->Checkbutton(-text,$word,-relief,'ridge',-justify,'right',-takefocus,1,
					      -selectcolor,'blue',-indicatoron,0,-variable,\$status1[$size1++],
					      -disabledforeground,'blue',-activebackground,'dark green',
					      -activeforeground,'white');
	    
	    #keep track of $id for configuring the checkbuttons
	    push @id1,$label1;

	    #keep track of the actual object to delete it later
	    push @del1,$canvas->createWindow(150,$yvar,-anchor,'e',-window,$label1);

	    #increment the $yvar for the next object to insert
	    $yvar += $buff;    
	}
    }
    
    #change the scroll region because more objects were added
    $canvas->configure(-scrollregion,[ $canvas->bbox("all") ]);

    close(FILE);

    #update informational label for user knowledge
    $info = "File '$file1' loaded";
    &browse;
    
}
#-----------------------------------------------------------------------------
#load_1 end


#function that loads target file into the tool
sub load_2{
    #enables the flag for the size option
    $bopenflag = 0;
    
    $info = "opening file '$file2'...";
    
    #store file to see if a new one was entered    
    $holdfileold2 = $holdfile2;
    $holdfileold2 = "" if(!$holdfile2);
    $holdfile2 = $file2;
    
    #error checking when file is opened
    if(!open(FILE, "$file2")){
	$info = "Error opening '$file2'";
	$canvas->bell();
	return(-2);
    }
    
    #clear out the old sentence
    undef $sentence2;

    #clears the previous connections
    &clear_lines;

    #remove the old words from the canvas 
    while(@del2){
	$canvas->delete(pop @del2);
    }

    #clear the id's from the past file
    undef @del2;

    #clears the canvas text for file 2
    while(@id2){
	$d = (pop @id2);
	$d->destroy();
    }

    #undefines the id's from file 2
    undef @id2;
    
    
    #clear the status array for the checkbuttons in list 2
    $size2 = $active2 = 0;
    undef @status2;

#This if statement takes care of the line-by-line loading
    if($cb_value){
	#reset the line number if a new file was opened
	$linenum2 = 0 unless($holdfileold2 eq $holdfile2);
	$linenum2 = 0 if($linenum2 < 0);

	#find the needed line
	for my $i (0..$linenum2){
	    $line = <FILE>;
	}

	#if there is no line, let the user know the file is finished
	if(!$line){
	    $info = "No more lines in the file";
	    $linenum2 = 0;
	    return;
	}
	close (FILE);
	
	#add the file to the history
	$entry2_w->historyAdd($file2) if($entry2_w->can('historyAdd'));

	#set the yvaraiable to the proper screen distance
	my $yvar = 50;

	#keep the sentence for viewing later
	$sentence2 = $line;

	#parse the line
	$line =~ s/[^\S ]//g;    #remove all whitespace except spaces
	$line =~ s/  +/ /g;   #remove multiple spaces

	#split up the line into an array
	my @temp = split / /, $line;

	#process the line word-by-word
	foreach $word (@temp){
	    #make word labels
	    my $word = $word . " " x (10-length($word));
	    my $label2 = $canvas->Checkbutton(-text,$word,-relief,'ridge',-justify,'left',-takefocus,1,
					      -selectcolor,'blue',-indicatoron,0,-variable,\$status2[$size2++],
					      -disabledforeground,'blue',-activebackground,'dark green',
					      -activeforeground,'white');
	    
	    #keep track of $id for configuring the checkbuttons
	    push @id2,$label2;

	    #keep track of the actual object to delete it later
	    push @del2,$canvas->createWindow(300,$yvar,-anchor,'w',-window,$label2);

	    #increment the $yvar for the next object to insert
	    $yvar += $buff;    
	}
	#change the scroll region because more objects were added
	$canvas->configure(-scrollregion,[ $canvas->bbox("all") ]);

	close(FILE);

	#update informational label for user knowledge
	$info = "Line $linenum2 from file '$file2' loaded";

	#increment the line number
	$linenum2++;

	#make sure the words are enabled/disabled as needed
	&browse;

	#exit the function because it is finished loading
	return;
    }

    #This section is executed on a regular loading of a file (not line-by-line)


    #save filename for save function, to print to a savefile in case
    #the user changes the entry1 widget entry.
    $entry2_w->historyAdd($file2) if($entry2_w->can('historyAdd'));
    $keepfile2 = $file2;
    
    #set $yvar to 50 for inserting position
    my $yvar = 50;
    
    #This while loop seperates the words in the file, makes widgets for
    #each word, and inserts them into the canvas. It also makes the null widgets.
    while(<FILE>) {
	
	#keep the sentence for viewing later
	$sentence2 = $sentence2 . $_;

	#parse the file
	$_ =~ s/[^\S ]//g;    #remove all whitespace except spaces
	$_ =~ s/  +/ /g;      #remove multiple spaces

	#split up the line into an array
	my @temp = split / /, $_;

	#process the line word-by-word
	foreach $word (@temp){
	    #make word labels
	    my $word = $word . " " x (10 - length($word));
	    my $label2 = $canvas->Checkbutton(-text,$word,-relief,'ridge',-justify,'left',-takefocus,1,
					      -selectcolor,'blue',-indicatoron,0,-variable,\$status2[$size2++],
					      -disabledforeground,'blue',-activebackground,'dark green',
					      -activeforeground,'white');
	    
	    #keep track of id to configure the checkbuttons later
	    push @id2,$label2; 

	    #keep track of the actual objects to delete them later
	    push @del2,$canvas->createWindow(300,$yvar,-anchor,'w',-window,$label2);

	    #increment the $yvar for the next insertion's position
	    $yvar += $buff;
	}
    }
    
    #change the scroll region because new elements were inserted    
    $canvas->configure(-scrollregion,[ $canvas->bbox("all") ]);

    close(FILE);

    #update informational label for user knowledge
    $info = "File '$file2' loaded";
    &browse;
}
#-----------------------------------------------------------------------------
#load_2 end


#This function makes a "null connection" if a word in one file has no
#translation into the other file.
sub nullcon {   
    #clear out temp arrays @list1 and @list2 from past connections
    undef @list1;
    undef @list2;

    #checks for browse mode
    if($rb_value eq 'Browse'){
	$info = "Cannot connect in browse mode!";
	$canvas->bell();
	return;
    }

    #These 2 while loops get the selected elements to connect
    my $i = 0;
    while($i < @status1){
	if($status1[$i]){
	    push @list1,$i;
	}
	$i++;
    }    
    $i = 0;
    while($i < @status2){
	if($status2[$i]){
	    push @list2,$i;
	}
	$i++;
    }
    

    #error checking if nothing was selected
    if(!@list1 && !@list2){
    	$info = "ERROR: Nothing Selected For Null connect";
	$entry1_w->bell();
	return;
    }

    #error checking if items from both lists were selected
    if(@list1 && @list2){
    	$info = "ERROR: Items Selected From Both Lists";
	$entry1_w->bell();
	return;
    }
    

    #This if statement is entered if there is something selected from the first
    #text file to "null connect", and there is nothing selected from file 2
    if(@list1){
		
	#this for loop makes a null connection for each selected item in the first list
	foreach (@list1) {
	    #save the indexes + 1 for the blinker-style file
	    $i = $_+1;

	    #looks through all the connections, and doesn't connect if the connection is 
	    #already there
	    $foundflag = 0;
	    foreach(@blinkarray){
		if($_ =~ /^$i 0$/){
		    $foundflag = 1;
		    $id1[$_]->deselect;
		    $info = "null connect to $_ has already been done";
		    last;
		}
	    }
	    #skip this connection if it has already been done
	    next if($foundflag == 1);

	    #continue if connection hasn't been done yet
	    push @blinkarray, "$i 0";
	    
	    #un-highlight the selected items,change to "null" color
	    $id1[$_]->deselect();
	    $id1[$_]->configure(-background, $nullback, -foreground, $nullfore,-disabledforeground,"white");
	    

	    #keep last element for easier use of the arrow keys
	    $active1 = $_;	    
	}
    }
    
    #This if statement is entered if there is something selected from the second
    #text file to "null connect", and there is nothing selected from file 1
    elsif(@list2){

	#this for loop makes a null connection for each selected item in the second list
	foreach (@list2) {
	    #save the indexes + 1 for the blinker-style file
	    $i = $_+1;
	    
	    #looks through all the connections, and doesn't connect if the connection is 
	    #already there
	    $foundflag = 0;
	    foreach(@blinkarray){
		if($_ =~ /^0 $i$/){
		    $foundflag = 1;
		    $id2[$_]->deselect;
		    $info = "null connect to $_ has already been done";
		    last;
		}
	    }
	    #skip this connection if it has already been done
	    next if($foundflag == 1);

	    #continue if connection hasn't been done yet
	    push @blinkarray, "0 $i";

	    #un-highlight the selected items
	    $id2[$_]->deselect();
	    $id2[$_]->configure(-background, $nullback, -foreground, $nullfore,-disabledforeground,"white");

	    #keep last element for easier use of the arrow keys
	    $active2 = $_;
	}
    }
}
#-----------------------------------------------------------------------------
#nullcon end


#This function makes a connection if there is something selected from the 
#source file, as well as the target file
sub con {
    
    #clears out the old lists from past connections  
    undef @list1;
    undef @list2;
  
    #checks for browse mode
    if($rb_value eq 'Browse'){
	$info = "Cannot connect in browse mode!";
	$canvas->bell();
	return;
    }

    #These 2 while loops get the selected elements to connect
    my $i = 0;
    while($i < @status1){
	if($status1[$i]){
	    push @list1,$i;
	}
	$i++;
    }    
    $i = 0;
    while($i < @status2){
	if($status2[$i]){
	    push @list2,$i;
	}
	$i++;
    }
    
    #error checking to make sure a word is selected from both lists
    if(!@list1){
	$info = "ERROR: Nothing Selected From The Source Text";
	$entry1_w->bell();
	return;
    }
    if(!@list2){
	$info = "ERROR: Nothing Selected From The Target Text";
	$entry1_w->bell();
	return;
    }


    #These nested for loops do the actual connecting and drawing of connections
    foreach $i (@list1){
	#clear selection in the list
	$id1[$i]->deselect;
	
	#keep active item for easier use of arrow keys
	$active1 = $i;

	foreach $j (@list2){
	    #increment the indexes to store them in the blinker-style
	    my $temp1 = $i+1;
	    my $temp2 = $j+1;
	    
	    #clear selection in the list
	    $id2[$j]->deselect;

	    #keep active item for easier use of arrow keys	    
	    $active2 = $j;

	    #looks through all the connections, and doesn't connect if the connection is 
	    #already there
	    my $foundflag = 0;
	    foreach(@blinkarray){
		if($_ =~ /^$temp1 $temp2$/){
		    $foundflag = 1;
		    $info = "connection $i to $j has already been done";
		    last;
		}
	    }
	    #skip this connection if it has already been done
	    next if($foundflag == 1);
	    
	    $id1[$temp1-1]->configure(-background, $connected);
	    $id2[$temp2-1]->configure(-background, $connected);

	    #find correct coordinates, and save indexes in blinker-style file
	    push @blinkarray, "$temp1 $temp2";
	    my $x1 = 150;
	    my $y1 = 50 + $buff * $i;
	    my $x2 = 300;
	    my $y2 = 50 + $buff * $j;
	    
	    #keep track of lines for the undo function
	    push @lines, $canvas->createLine($x1,$y1,$x2,$y2);
	}
    }
}
#-----------------------------------------------------------------------------
#con end


#This function clears the connections, but leaves the files intact
sub clear_lines{

        
    #puts into edit mode to load connections
    my $flageroo = 0;
    if($rb_value eq 'Browse'){
	$rb[1]->invoke;
	$flageroo = 1;
    }
    
    #undoes the null connections
    while(@blinkarray){
	&undo;
    }

    #put back into browse mode if necessary
    if($flageroo){
	$rb[0]->invoke;
    }

    #clear the arrays used for connections
    undef @blinkarray;
    undef @redo;
    undef @lines;
    
    $info = "Connections Clear";
    &browse;
}
#-----------------------------------------------------------------------------
#clear_lines end


#This function clears the lists, entry widgets, and all the connections   
sub clear_tot{
    #enables the flag for the size option
    $bopenflag = 0;

    #clears out the arrays used for various purposes
    undef @blinkarray;
    undef @redo;
    undef @status1;
    undef @status2;
    undef $holdfile;
    undef $holdfileold;
    undef $holdfile2;
    undef $holdfileold2;
    undef $sentence1;
    undef $sentence2;
    
    #clears out the status of the words, and other variables to restart
    $size1 = $linenum = $linenum2 = $size2 = $active1 = $active2 = 0;

    #clears out the entry widgets
    $entry1_w->delete(0,"end");
    $entry2_w->delete(0,"end");

    #clears the connection lines from the canvas
    while(@lines){
	$canvas->delete(pop @lines);
    }

    #deletes the buttons from the canvas
    while(@del1){
	$canvas->delete(pop @del1);
    }
    while(@del2){
	$canvas->delete(pop @del2);
    }

    #clear source file from canvas
    while(@id1){
	$d = (pop @id1);
	$d->destroy();
    }
    #clear target file from canvas
    while(@id2){
	$d = (pop @id2);
	$d->destroy();
    }

    #undefines the id's after they have been removed from the canvas
    undef @lines;
    undef @del1;
    undef @del2;
    undef @id1;
    undef @id2;
    
    #gives the focus to the first entry widget to re-enter a file
    $entry1_w->focus();

    #change the scroll region because new elements were inserted    
    $canvas->configure(-scrollregion,[ $canvas->bbox("all") ]);
    
    $info = "Clear Complete";
}
#-----------------------------------------------------------------------------
#clear_tot end



#This function undoes a connection, which can be done in 3 different ways (See README)
sub undo{
    #checks if there is a connection to undo
    if(!@blinkarray){
	$info = "No Connections to Undo";
	$entry1_w->bell();
	return;
    }

    #checks for browse mode
    if($rb_value eq 'Browse'){
	$info = "Cannot undo moves in browse mode!";
	$entry1_w->bell();
	return;
    }

    #clear out old lists from this function
    undef @list1;
    undef @list2;
    undef @splicelines;
    undef @spliceblink;
    undef @save;

    #These 2 while loops get the selected elements to undo
    my $i = 0;
    while($i < @status1){
	if($status1[$i]){
	    push @list1,$i;
	}
	$i++;
    }    
    $i = 0;
    while($i < @status2){
	if($status2[$i]){
	    push @list2,$i;
	}
	$i++;
    }

    #checks for no selected items, then just undoes the last line
    if(!@list1 && !@list2){
    
	#remove entry from blinker-style array, and parse it. Indexes stored in @con.
	my $con = pop @blinkarray;
	my @con = split / /,$con;
	
	#error checking to see if the connection is valid
	if(@con != 2){
	    $info = "Connection to undo is in wrong format";
	    return;
	}

	#put the connection in the redo array 
	push @redo,$con;
	
	#removes the last line drawn if it is a regular connection
	$canvas->delete(pop @lines) if($con[0] != 0 && $con[1] != 0);

	#checks for a null connection, and changes color back to normal
	if($con[0] == 0){
	    $id2[$con[1]-1]->configure(-background,$normal,-foreground,"black",-disabledforeground,"blue");
	}
	elsif($con[1] == 0){
	    $id1[$con[0]-1]->configure(-background,$normal,-foreground,"black",-disabledforeground,"blue");
	}

	#check for empty word, change color back
	elsif($con[0] != 0 && $con[1] != 0){
	    $flag1 = $flag2 = 0;
	    #checks for connections to either word that was undone
	    foreach(@blinkarray){
		my @tmp = split / /,$_;
		$flag1++ if($tmp[0] == $con[0]);
		$flag2++ if($tmp[1] == $con[1]);
	    }
	    #if there are no more connections to the words, then change color back to normal
	    $id1[$con[0]-1]->configure(-background,$normal) if($flag1 == 0);
	    $id2[$con[1]-1]->configure(-background,$normal) if($flag2 == 0);
	}
    }

    #does this if there are selected items to undo 
    elsif(@list1 || @list2){

	#checks the length of @blinkarray to compare later to see if something was undone or not
	my $blinkerlen = @blinkarray;

	#error checking to see if there is 1 word selected from each file
	if(@list1 > 1 ||  @list2 > 1){
	    $info = "Please select only one word to undo at a time";
	    $canvas->bell();
	    return;
	}
	
	#does this if an item is selected from list 1 and 2
	if(@list1 == 1 && @list2 == 1){
	    #this for loop looks through each connection, looking for a match of the selected items
	    for($i = 0; $i < @blinkarray; $i++){

		#must match the index with the blinkarray style indexes
		my $t1 = $list1[0]+1;
		my $t2 = $list2[0]+1;

		#look for a match in the @blinkarray(list of connections)
		if($blinkarray[$i] =~ /^$t1 $t2$/){
		    #put the connection in the redo array 
		    push @redo,$blinkarray[$i];
		    #delete the connection from @blinkarray
		    splice(@blinkarray,$i,1);
		    
		    #unselect the selected items
		    $id1[$list1[0]]->deselect;
		    $id2[$list2[0]]->deselect;
		    
		    #check for empty word, change color back
		    $flag1 = $flag2 = 0;
		    #checks for connections to either word that was undone
		    foreach(@blinkarray){
			my @tmp = split / /,$_;
			$flag1++ if($tmp[0]-1 == $list1[0]);
			$flag2++ if($tmp[1]-1 == $list2[0]);
		    }
		    #if there are no more connections to the words, then change color back to normal
		    $id1[$list1[0]]->configure(-background,$normal) if($flag1 == 0);
		    $id2[$list2[0]]->configure(-background,$normal) if($flag2 == 0);
		    
		

		    #this checks the lines for the matching coordinates 
		    for($l = 0; $l < @lines; $l++){
			@coors = $canvas->coords($lines[$l]);
			$one = 50 + ($list1[0] * $buff);
			$three = 50 + ($list2[0] * $buff);

			#if a matching line coordinate is found, delete the line from canvas and array
			if($coors[1] == $one && $coors[3] == $three){
			    $canvas->delete($lines[$l]);
			    splice(@lines,$l,1);
			    last;
			}
		    }
		    last;
		}
	    }
	    #does this if no connection was found to undo
	    if(@blinkarray == $blinkerlen){
		#unselect the selected items
		$id1[$list1[0]]->deselect;
		$id2[$list2[0]]->deselect;
		$info = "No connection found to undo";
		return;
	    }
	}

	#does this if an item is selected from list 1 but not list 2
	elsif(@list1 == 1 && @list2 == 0){
	    
	    #looks for connections to the element selected in list1
	    for($i = 0; $i < @blinkarray; $i++){
		#adjust to Blinker file format
		my $t1 = $list1[0]+1;
		
		#if a match is found
		if($blinkarray[$i] =~ /^$t1 ./){

		    #put the connection in the redo array 
		    push @redo,$blinkarray[$i];
		    #save the matched connections
		    push @save,$blinkarray[$i];
		    push @spliceblink, $i;
		    $counter++;
		    $id1[$list1[0]]->deselect;
		}
	    }
	    #error checking if no connections were found to undo
	    if($counter == 0){
		$info = "No connections from this word to undo";
		$id1[$list1[0]]->deselect;
		return;
	    }

	    #do this for eatch match
	    foreach(@save){
		@temp = split / /,$_;
		#this checks the lines for the matching coordinates unless it is a null connection
		if($temp[1] != 0){
		    for($l = 0; $l < @lines; $l++){
			@coors = $canvas->coords($lines[$l]);
			$one = 50 + (($temp[0]-1) * $buff);
			$three = 50 + (($temp[1]-1) * $buff);
			
			#if a matching line coordinate is found, delete the line from canvas and array
			if($coors[1] == $one && $coors[3] == $three){
			    $canvas->delete($lines[$l]);
			    push @splicelines,$l;
			}
		    }

		}
		#change the color of the selected word back to normal - no more connections to it
		$id1[$temp[0]-1]->configure(-background,$normal,-foreground,"black",-disabledforeground,"blue");
		
	    }
	    #delete the matching items from the blink array and lines array
	    my $count = 0;
	    foreach(@spliceblink){
		#delete the connection from @blinkarray
		splice(@blinkarray,$_-$count,1); 
		$count++;
	    }


	    #this goes through the save array again, after blinkarray has been spliced.  It looks for
	    #words in the second list that no longer have connections to them, and changes the color back to normal
	    foreach(@save){
		@temp = split / /, $_;
		if($temp[1] != 0){
		    #check for empty word, change color back
		    $flag2 = 0;
		    #checks for connections to second word that was undone
		    foreach $b (@blinkarray){
			my @tmp = split / /,$b;
			$flag2++ if($tmp[1] == $temp[1]);
		    }
		    #if there are no more connections to the words, then change color back to normal
		    $id2[$temp[1]-1]->configure(-background,$normal) if($flag2 == 0);
		}
	    }

	    $count = 0;
	    foreach(@splicelines){
		#delete the connection from the lines array
		splice(@lines,$_-$count,1);
		$count++;
	    }
	    #does this if no connection was found to undo
	    if(@blinkarray == $blinkerlen){
		#unselect the selected items
		$id1[$list1[0]]->deselect;
		$info = "No connection found to undo";
		return;
	    }
	    
	}
	
	#does this if there is something selected from list 2, but not list 1
	elsif(@list1 == 0 && @list2 == 1){

	    for($i = 0; $i < @blinkarray; $i++){
		#adjust to Blinker file format
		my $t2 = $list2[0]+1;

		#if a match is found
		if($blinkarray[$i] =~ /. $t2$/){

		    #put the connection in the redo array 
		    push @redo,$blinkarray[$i];
		    #save the matched connections
		    push @save,$blinkarray[$i];
		    push @spliceblink, $i;
		    $counter++;
		    $id2[$list2[0]]->deselect;
		}
	    }
	    #error checking if no connections were found to undo
	    if($counter == 0){
		$info = "No connections from this word to undo";
		$id2[$list2[0]]->deselect;
		return;
	    }

	    #do this for each match
	    foreach(@save){
		my @temp = split / /,$_;

		#this checks the lines for the matching coordinates unless it is a null connection
		if($temp[0] != 0){
		    for($l = 0; $l < @lines; $l++){
			@coors = $canvas->coords($lines[$l]);
			$one = 50 + (($temp[0]-1) * $buff);
			$three = 50 + (($temp[1]-1) * $buff);
			
			#if a matching line coordinate is found, delete the line from canvas and array
			if($coors[1] == $one && $coors[3] == $three){
			    $canvas->delete($lines[$l]);
			    push @splicelines,$l;
			}
		    }
		}
		#change the selected word back to normal
		$id2[$temp[1]-1]->configure(-background,$normal,-foreground,"black",-disabledforeground,"blue");
		
	    }

	    #delete the matching items from the blink array and lines array
	    my $count = 0;
	    foreach(@spliceblink){
		#delete the connection from @blinkarray
		splice(@blinkarray,$_-$count,1); 
		$count++;
	    }

	    #this goes through the save array again, after blinkarray has been spliced.  It looks for
	    #words in the first list that no longer have connections to them, and changes the color back to normal
	    foreach(@save){
		@temp = split / /, $_;
		if($temp[0] != 0){
		    #check for empty word, change color back
		    $flag1 = 0;
		    #checks for connections to first word that was undone
		    foreach $b (@blinkarray){
			my @tmp = split / /,$b;
			$flag1++ if($tmp[0] == $temp[0]);
		    }
		    #if there are no more connections to the words, then change color back to normal
		    $id1[$temp[0]-1]->configure(-background,$normal) if($flag1 == 0);
		}
	    }


	    $count = 0;
	    foreach(@splicelines){
		#delete the connection from the lines array
		splice(@lines,$_-$count,1);
		$count++;
	    }
	    #does this if no connection was found to undo
	    if(@blinkarray == $blinkerlen){
		#unselect the selected items
		$id2[$list2[0]]->deselect;
		$info = "No connection found to undo";
		return;
	    }
	}
    }
    
    $info = "Connection Undone";
}
#-----------------------------------------------------------------------------
#undo end


#This function redoes one line at a time, if there was something undone
sub redo{
    #error checking if redo array is empty
    if(!@redo){
	$info = "No connections to redo";
	$entry1_w->bell();
	return;
    }

    #checks for browse mode
    if($rb_value eq 'Browse'){
	$info = "Cannot redo moves in browse mode!";
	$entry1_w->bell();
	return;
    }

    #gets the connection to redo
    my $re = pop @redo;
    my @re = split / /,$re;

    #checks for the case of a null connection from file 1
    if($re[0] == 0 && $re[1] != 0){
	$id2[$re[1]-1]->select();
	&nullcon;
    }
    
    #checks for the case of a null connection from file 2    
    elsif($re[1] == 0 && $re[0] != 0){
	$id1[$re[0]-1]->select();
	&nullcon;
    }
    
    #if not a null connection, it does the regular connection
    else{
	$id1[$re[0]-1]->select();
	$id2[$re[1]-1]->select();
	&con;
    } 
    $info = "Connection Redrawn";
}    
#-----------------------------------------------------------------------------
#redo end


#This function makes a pop-up button when the help menu option is used.
#It displays the README, which is the best help users can find.
sub help_pop{
    #make a toplevel widget
    my $t1 = $mw->Toplevel();
    #withdraw to use a different pop-up method
    $t1->withdraw;
    $t1->title("Help");
    $f = $t1->Frame->pack(-side,'bottom');
    $help = $t1->Scrolled("Markdown",
        -scrollbars => 'soe',
        -background =>'white',
        -selectbackground =>'blue',
        -selectforeground => 'white',
    )->pack(-expand => 1, -fill =>'both');
    
    #error checking for opening the README file
    my $help_filename = 'README.md';
    open(my $fh, '<:encoding(UTF-8)', $help_filename);
    if(!$fh){
        $info = "Error opening '$help_filename'";
        $t1->withdraw;
        $entry1_w->bell();
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
    $f->Button(-text,"Close",-background,"black",-foreground,"white",-command,sub{$t1->withdraw})->pack(-side,'bottom',
													-expand,1,
													-fill,'x');
   
    #makes the pop-up button appear
    $t1->Popup;
    $t1->focus();

}
#-----------------------------------------------------------------------------
#help_pop end


#This function makes a pop-up for the keyboard shortcut information
sub kbd_pop{
    #make a toplevel widget
    my $t2 = $mw->Toplevel();
    #withdraw to use a different pop-up method 
    $t2->withdraw();
    $t2->title("Keyboard Shortcuts");
    
    #makes the label with the keyboard shortcut information
    $t2->Label(-text,"The following are keyboard shortcuts when the lists have focus:\n\nKey: (depends on the mouse):\nBoth Mouse Buttons or Right Mouse Button-->Makes a connection with the selected words\nKey: Ctrl+c-->Makes a connection with the selected words\nKey: Ctrl+n-->Makes a null connection\nKey: Ctrl+u-->Undoes the last connection\nKey: Ctrl+r-->Redoes the last undone connection\nKey: spacebar-->Selects the underlined item if the mouse is not used\nKey: Ctrl+s-->Saves the Alpaco file\nKey: Ctrl+o-->Opens an Alpaco file")->pack(-side,'top');
    
    #makes the button to close the window
    $t2->Button(-text,"Close",-background,"black",-foreground,"white",-command,sub{$t2->withdraw})->pack(-side,'bottom',
													 -expand,1,
													 -fill,'x');
    
    #makes the pop-up button appear
    $t2->Popup;
    $t2->focus();
    
}
#-----------------------------------------------------------------------------
#kbd_pop end


#This function makes a pop-up for the 'about' information
sub about_pop{
    #makes a toplevel widget
    my $t3 = $mw->Toplevel();
    #withdraw to use a different pop-up method
    $t3->withdraw();
    $t3->title("About");
    
    #makes a frame widget
    $fr = $t3->Frame->pack(-side,'bottom');
    #makes a text widget for the about information
    $about = $t3->Text(
		       -selectbackground,'blue',
		       -selectforeground,'white')->pack(-expand,1,-fill,'both');

    #inserts the necessary information
    $about->insert("end","Alpaco (Aligner for Parallel Corpora)\n\n");
    $about->insert("end","Version 1.1\n\n");
    $about->insert("end","Research project by Dr. Ted Pedersen and Brian Rassier\n\n");
    $about->insert("end","This program is free software; you can redistribute it and/or\nmodify it under the terms of the GNU General Public License\nas published by the Free Software Foundation; either version 2\nof the License, or (at your option) any later version.\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details\n");
    
    
    #makes a button to close the window
    $fr->Button(-text,"Close",-background,"black",-foreground,"white",-command,sub{$t3->withdraw})->pack(-side,'bottom',
													-expand,1,
													 -fill,'x');
													 
    #disables the text widget for read-only access						 
    $about->configure(-state,'disabled');    		
											     
    #makes the pop-up button appear
    $t3->Popup;
    $t3->focus();

   
}
#-----------------------------------------------------------------------------
#about_pop end


#This function function makes a pop-up for the open Alpaco file 
sub open_pop{
    
    #makes a toplevel widget with entry widget and open/cancel buttons
    $t4 = $mw->Toplevel();
    #withdraw for use of a different pop-up method
    $t4->withdraw();
    $t4->title("Open Alpaco");
    $t4->Label(-text,"Open Filename:")->pack(-side,'top');
    $e = $t4->Entry(-textvariable,\$open,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    
    $frame = $t4->Frame->pack(-side,'bottom');
    $frame->Button(-text,"Open",-background,"black",-foreground,"white",-command,\&open2)->pack(-side => 'left', -padx => 5);
    $frame->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t4->withdraw})->pack(-side,'left');

    
    #makes the find button that will help find an alpaco file
    $frame->Button(-text,"Find Alpaco File", -background,"black",-foreground,"white",-command,\&find_al)->pack(-side,'bottom',-padx,25);


    #define hard-enter callback for entry one
    $e->bind("<Return>",\&open2);
    
    #makes the pop-up button appear
    $t4->Popup;
    $t4->focus();

    #gives the entry widget the focus to start with
    $e->focus();
       
}
#-----------------------------------------------------------------------------
#open_pop end



#sub-function when a file is to be opened-called by open_pop and others
sub open2{
    #error checking
    if(!open(FH, "$open")){
	$info = "Error opening '$open'";
	$entry1_w->bell();
	return(-1);
    }
    
    #gets the first line, which should be 2 filenames
    my $line = <FH>;
    chomp $line;
    my @temp = split / /, $line;
    
    #error checking for format
    if(@temp != 2){
	$info = "Error: '$open' is wrong format";
	$entry1_w->bell();
	return(-1);
    }
    
    #must open as a blinker file if no files are listed at the top (use equation)
    if($temp[0] !~ /[a-zA-z]+/ && $temp[1] !~ /[a-zA-z]+/){
	close(FH);
	#set this variable to the file the user found
	$sent = $open;
	#open blinker pop-up
	&openb;
	#remove the pop-ups
	$t6->withdraw if(Exists($t6));
	$t4->withdraw if (Exists($t4));
	#do not need to continue loading, so return
	return;
    }
    
    #enables the flag for the size option
    $bopenflag = 0;
    
    #clear out lines and connections to start fresh with the opened file
    &clear_tot;
    
    #gets the file names from the input file, and loads them
    $file1 = $temp[0];
    $file2 = $temp[1];
    &load_files;
    
    #puts into edit mode to load connections
    my $flageroo = 0;
    if($rb_value eq 'Browse'){
	$rb[1]->invoke;
	$flageroo = 1;
    }
    
    #This while loop gets the connections, and loads them by selecting the words
    #manually, then calling the connection subroutines
    while($line = <FH>){
	#parse the indexes
	chomp $line;
	my @pair = split / /,$line;
	
	#error checking for bad format
	next if(@pair != 2);
	
	#checks for the case of a null connection from file 1
	if($pair[0] == 0 && $pair[1] != 0){
	    $id2[$pair[1]-1]->select();
	    &nullcon;
	}
	
	#checks for the case of a null connection from file 2    
	elsif($pair[1] == 0 && $pair[0] != 0){
	    $id1[$pair[0]-1]->select();
	    &nullcon;
	}
	
	#if not a null connection, it does the regular connection
	else{
	    $id1[$pair[0]-1]->select();
	    $id2[$pair[1]-1]->select();
	    &con;
	}
	
    }
    close(FH);
    
    #puts back into browse mode if necessary
    if($flageroo == 1){
	$rb[0]->invoke;
    }
    
    $info = "File Opened";
    $t4->withdraw if(Exists($t4));
}
#-----------------------------------------------------------------------------
#open2 end



#This function makes a pop-up for the save Alpaco file
sub save_pop{
    #makes a toplevel widget with entry widget and save/cancel buttons
    $t5 = $mw->Toplevel();
    #withdraw to use a different popup method
    $t5->withdraw();
    $t5->title("Save Alpaco");
    $t5->Label(-text,"Save Filename:")->pack(-side,'top');
    $e = $t5->Entry(-textvariable,\$save,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    $t5->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t5->withdraw})->pack(-side,'bottom');
    $b = $t5->Button(-text,"Save",-background,"black",-foreground,"white",-command,\&save2)->pack(-side,'bottom');
    
    
    #define enter callback for entry one
    $e->bind("<Return>",sub{save2(); });
    
    #makes the pop-up button appear
    $t5->Popup;
    $t5->focus();

    #gives the entry widget the keyboard focus to start with
    $e->focus();

}
#-----------------------------------------------------------------------------
#save_pop end


#subfunction that is called if a file is to be saved-called by save_pop and others
sub save2{
    
    #error checking to check for files
    if(!$save){
	$info = "Error: Please enter a filename to save to";
	$entry1_w->bell();
	return(-1);
    }
    if((!$keepfile1 || !$keepfile2) && (!$cb_value)){
	$info = "Error: Please enter the 2 list filenames to save";
	$entry1_w->bell();
	return(-1);
    }

#CHECK IF THE FILE EXISTS HERE BEFORE OPENING $save
#IF IT ALREADY EXISTS, SEND TO GENERIC "IS THIS OK" POP UP


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
	$entry1_w->waitVariable(\$OK);
    }

    #if $OK equals 0, that means the user does not want to save over
    #the existing file, so return.
    if($OK == 0){
	return;
    }

    if(!open(FH, ">$save")){
	$info = "Error opening '$save'";
	$entry1_w->bell();
	return(-1);
    }
    
    #print filenames to intermediate file if necessary
    print FH "$keepfile1 $keepfile2\n" if(!$cb_value && !($keepfile1 eq "Blinktemp1" && $keepfile2 eq "Blinktemp2"));
    
    #prints the blinker-style connection information to the file
    foreach(@blinkarray){
	print FH $_,"\n";
    }
    
    close(FH);
    $t5->withdraw if (Exists($t5));
}
#-----------------------------------------------------------------------------
#save2 end


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


#This function makes a pop-up for the open blinker file option and opens the file if valid
sub open_blink{

    #makes a toplevel widget with entry widget and open/cancel buttons   
    $t6 = $mw->Toplevel();
    #withdraw to use different pop-up method
    $t6->withdraw();
    $t6->title("Open Blink-style");
    $t6->Label(-text,"Sentpair File:")->pack(-side,'top');
    $obe1 = $t6->Entry(-textvariable,\$sent,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    $t6->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t6->withdraw})->pack(-side,'bottom');
    $blop = $t6->Button(-text,"Open",-background,"black",-foreground,"white",-command,\&openb)->pack(-side,'bottom');
    
    
    #define hard enter callback for entry one
    $obe1->bind("<Return>",\&openb);
    
    #makes the pop-up button appear
    $t6->Popup;
    $t6->focus();

    #starts the entry widget with the keyboard focus
    $obe1->focus();


}
#-----------------------------------------------------------------------------
#open_blink end



#subfunction that is called if a blinker file is to be opened, by open_blink
sub openb{
    
    #error detection for wrong naming scheme
    if($sent !~ /samp..?\.SentPair./){
	$info = "SentPair file entered is not valid";
	$t6->withdraw if(Exists($t6));
	$entry1_w->bell();
	return;
    }
    
    #turns off the next line option if a blinker-style file is loaded because
    #this option is only used for raw text files.
    if($cb_value){
	$cb->invoke();
    }
    
    #clear the total entry if the SentPair file is valid
    &clear_tot;
    

    
    #packs the blinker buttons if this is the first blinker file opened 
    if($blinkfile eq ""){

	#Previous and next buttons added here, since a blinker file has been opened
	$prev->pack(-side,'left',-anchor,'w',-pady,5);
	#makes the label for the next/prev
	$nextframe->Label(-text,"File Pair",-relief,'ridge')->pack(-side,'left',-anchor,'w');
	$next->pack(-side,'left',-anchor,'w',-pady,5);
	
	#pack the annotator buttons here, since a blinker file has been opened
	$prevan->pack(-side,'left',-anchor,'w',-pady,5);
	#makes the label for the next/prev
	$nextanframe->Label(-text,"Annotator",-relief,'ridge')->pack(-side,'left',-anchor,'w');
	$nextan->pack(-side,'left',-anchor,'w',-pady,5);
    }

    #set #blinkfile to the file loaded
    $blinkfile = $sent;

    #get the necessary numbers from the SentPair input file, and calculate the correct
    #verse and english/french files to use to map the connections
    $temp1 = $temp2 = $temp3 = $sent;
    $temp1 =~ s/.*samp([0-9]+)\.SentPair.+/$1/;       #gets the samp#
    $temp2 =~ s/.*samp[0-9]+\.SentPair([0-9]+)/$1/;   #gets the SentPair#
    $ver =(($temp1 -1) * $v) + ($temp2 + 1);          #uses the equation
    $f = floor($ver/$v)+1;
    $ver = $ver % $v;
    
    
    #sets the versenum to the number (0-9) of the verse number in the en/fr files
    #and sets it to 10 if $ver%10 = 0, then decrements $f to match the correct file
    $versenum = $ver;
    if($versenum == 0){
	$versenum = $v;
	$f--;
    }
    
    #find the prefix for the verse files
    $temp3 =~ s/^(.*)A[0-9]+.*/$1/;
    $enverse = $temp3 . "EN.sample." . $f;
    $frverse = $temp3 . "FR.sample." . $f;
    
    #open english verse if possible
    if(!open(FH1, "$enverse")){
	$info = "Error opening '$enverse'";
	$entry1_w->bell();
	return(-1);
    }
    #open french verse if possible
    if(!open(FH2, "$frverse")){
	$info = "Error opening '$frverse'";
	$entry1_w->bell();
	return(-1);
    }
    
    #check for valid verse number
    if($versenum !~ /^[0-9]+$/){
	$info = "Please enter a valid verse number";
	$entry1_w->bell();
	return(-1);
    }
    
    #skip to the correct verse for file 1
    for (1..$versenum){
	$line = <FH1>;
    }
    
    #open temp file to write the verse to
    if(!open(Btemp1, ">Blinktemp1")){
	$info = "Error opening 'Blinktemp1'";
	$entry1_w->bell();
	return(-1);
    }
    
    #print the verse to the temp file
    print Btemp1 $line;
    
    #skip to the correct verse for file 2
    for (1..$versenum){
	$line = <FH2>;
    }
    
    #open temp file to write verse to
    if(!open(Btemp2, ">Blinktemp2")){
	$info = "Error opening 'Blinktemp2'";
	$entry1_w->bell();
	return(-1);
    }
    
    #print the verse to the temp file
    print Btemp2 $line;
    
    #close files
    close(Btemp1);
    close(Btemp2);
    close(FH1);
    close(FH2);
    
    $file1 = "Blinktemp1";
    $file2 = "Blinktemp2";
    &load_files;
    
    #This section loads the connection information 
    
    #opens the connection file (samp##.SentPair#)
    if(!open(Pair, "$sent")){
	$info = "Error opening '$sent'";
	$entry1_w->bell();
	return(-1);
    }
    
    #puts into edit mode to load file
    $flageroo = 0;
    if($rb_value eq 'Browse'){
	$rb[1]->invoke;
	$flageroo = 1;
    }
    
    #This while loop gets the pairs of connections, and makes the connections by manually selecting
    #the words and using the con & nullcon functions
    while($line = <Pair>){
	#parse the connections
	chomp $line;
	my @pair = split / /,$line;
	
	#error checking for format
	next if(@pair != 2);
	
	#checks for a null connection from the english file
	if($pair[0] == 0 && $pair[1] != 0){
	    $id2[$pair[1]-1]->select();
	    &nullcon;
	}
	
	#checks for a null connection from the french file
	elsif($pair[1] == 0 && $pair[0] != 0){
	    $id1[$pair[0]-1]->select();
	    &nullcon;
	}
	
	#does a regular connection if no null connections are needed
	else{
	    $id1[$pair[0]-1]->select();
	    $id2[$pair[1]-1]->select();
	    &con;
	}
    }
    
    #closes the toplevel window
    $t6->withdraw if(Exists($t6));
    
    #puts back into browse mode if necessary
    if($flageroo == 1){
	$rb[0]->invoke;
    }
    
    $info = "Blinker File Opened";
}
#-----------------------------------------------------------------------------
#openb end



#This function saves a file with names on the subfiles. It can be used to change an equation-style
#file to the other format, or working line-by-line without equations. See the "Save Current Work to File"
#option in the README for more information.
sub save_blink{
    #makes a toplevel widget with 3 needed entry widgets and save/cancel/help buttons
    $t7 = $mw->Toplevel();
    #withdraw to use a different pop-up method 
    $t7->withdraw();
    $t7->title("File");
    $t7->Label(-text,"Save source text as:")->pack(-side,'top');
    $sbe1 = $t7->Entry(-textvariable,\$everse,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    $t7->Label(-text,"Save target text as:")->pack(-side,'top');
    $sbe2 = $t7->Entry(-textvariable,\$fverse,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    $t7->Label(-text,"Save Alpaco file as:")->pack(-side,'top');
    $sbe3 = $t7->Entry(-textvariable,\$conn,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w');
    #makes a frame to hold the buttons and the buttons
    $b_frame = $t7->Frame->pack(-side,'bottom');
    $b_frame->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t7->withdraw})->pack(-side,'right');
    $sbb = $b_frame->Button(-text,"Save",-background,"black",-foreground,"white",-command,\&saveb)->pack(-side,'right');

    #makes the help button which opens the help pop-up, and moves to the appropriate spot in the README
    $b_frame->Button(-bitmap,'questhead',
		     -command,sub{&help_pop;
				  #make text widget able to write to
				  $help->configure(-state,'normal');
				  #select the pertinent info
				  $help->tagAdd("MySel","460.0","474.0 lineend");
				  #moves to the right spot in the text widget		       	  
				  $help->see("MySel.first");
				  $help->configure(-state,'disabled');
			      })->pack(-side,'left',-padx,15);
    
    #define hard enter callback for entry widget 3
    $sbe3->bind("<Return>",\&saveb);

    #makes the pop-up button appear
    $t7->Popup;
    $t7->focus();

    #gives the first entry widget the focus to start with
    $sbe1->focus();  

}
#-----------------------------------------------------------------------------
#save_blink end


#this subfunction is called if a blinker file is saved, by save_blink
sub saveb{
    #check if they entered a name for the Alpaco file
    if($conn eq ""){
        $info = "Error: Please enter an Alpaco name to save to";
        $entry1_w->bell();
        return(-1);
    }
    
    #THIS SECTION CHECKS IF THE FILES EXISTS HERE BEFORE OPENING
    #IF THEY ALREADY EXISTS, SEND TO GENERIC "IS THIS OK" POP UP
#====================================================================   
    #This first section checks if the first file exists, and prompts
    #the user to decide if they want to overwrite it or not.

    #make $OK not 0 or 1, to see what it gets set at with the 
    #file_exists function
    $OK = "256";

    #if the $save file already exists, call file_exists pop-up
    if((-e $everse) && ($everse ne "SizeVerse1")){
	file_exists($everse);
    }
    #if the $save file already exists, then wait until the $OK variable
    #gets changed.  This variable gets changed to a 0 or 1 depending on
    #if the user chose cancel or OK to saving over the existing file
    if((-e $everse) && ($everse ne "SizeVerse1")){
	$entry1_w->waitVariable(\$OK);
    }

    #if $OK equals 0, that means the user does not want to save over
    #the existing file, so return.
    if($OK == 0){
	return;
    }

    #This is the start of the second section, that checks the second file.

    #make $OK not 0 or 1, to see what it gets set at with the 
    #file_exists function
    $OK = "256";

    #if the $save file already exists, call file_exists pop-up
    if((-e $fverse)&&($fverse ne "SizeVerse2")){
	file_exists($fverse);
    }

    #if the $save file already exists, then wait until the $OK variable
    #gets changed.  This variable gets changed to a 0 or 1 depending on
    #if the user chose cancel or OK to saving over the existing file
    if((-e $fverse) && ($fverse ne "SizeVerse2")){
	$entry1_w->waitVariable(\$OK);
    }

    #if $OK equals 0, that means the user does not want to save over
    #the existing file, so return.
    if($OK == 0){
	return;
    }

    #This is the start of the third section,which checks the third file.

    #make $OK not 0 or 1, to see what it gets set at with the 
    #file_exists function
    $OK = "256";

    #if the $save file already exists, call file_exists pop-up
    if((-e $conn)&& ($conn ne "sizetemp")){
	file_exists($conn);
    }
    #if the $save file already exists, then wait until the $OK variable
    #gets changed.  This variable gets changed to a 0 or 1 depending on
    #if the user chose cancel or OK to saving over the existing file
    if((-e $conn) && ($conn ne "sizetemp")){
	$entry1_w->waitVariable(\$OK);
    }

    #if $OK equals 0, that means the user does not want to save over
    #the existing file, so return.
    if($OK == 0){
	return;
    }
#====================================================================  
#END OF CHECKING IF FILES EXIST

    #open temp file to write the verse to
    if(!open(ENF, ">$everse")){
	$info = "Error opening 'Source Text'";
	$entry1_w->bell();
	return(-1);
    }
    
    #copy verse to file specified by user
    print ENF $sentence1;
    
    #open temp file to write the verse to
    if(!open(FRF, ">$fverse")){
	$info = "Error opening 'Target Text'";
	$entry1_w->bell();
	return(-1);
    }
    
    #copy verse to file specified by user
    print FRF $sentence2;
    
    close(FRF);
    close(ENF);
    
    #enables the flag for the size option
    $bopenflag = 0;
    
    #store files for the regular savepop. Don't change the entry boxes if the line-by-line
    #option is used so the line-by-line function can keep using the old files.
    if($cb_value){
	$keepfile1 = $everse;
	$keepfile2 = $fverse; 
    }
    elsif(!$cb_value){
	$file1 = $keepfile1 = $everse unless($everse eq "SizeVerse1");
	$file2 = $keepfile2 = $fverse unless($fverse eq "SizeVerse2"); 
    }
    
    #close pop-up
    $t7->withdraw if(Exists($t7));
    
    #CHECK IF THE FILES EXISTS HERE BEFORE OPENING
    #IF THEY ALREADY EXISTS, SEND TO GENERIC "IS THIS OK" POP UP

    #opens the connection file to write connections to
    if(!open(FH, ">$conn")){
	$info = "Error opening '$conn'";
	$entry1_w->bell();
	return(-1);
    }
    
    #print filenames and connections to blinker-style intermediate file
    print FH "$keepfile1 $keepfile2\n";
    
    #prints the connection information to the file
    foreach(@blinkarray){
	print FH $_,"\n";
    }
    
    close(FH);
    
    $info = "Work Saved";
}
#-----------------------------------------------------------------------------
#saveb end


#This function will change the space (vertically) between the words on the canvas 
sub resize {
    #disables the resize option if no files have been opened
    if($bopenflag == -1){
	$info = "ERROR: Can't resize unless 2 files have been opened";
	$entry1_w->bell();
	return;
    }

    #don't allow resize in line-by-line mode. Naming scheme gets complicated & the line number gets off
    if($cb_value){
	$info = "Can not resize in line-by-line raw text mode";
	$entry1_w->bell();
	return;
    }

    #finds which button was pressed (+ or -)
    my $who = $sizeframe->focusCurrent();
    
    #gets the text inside the button that was pressed
    my $txt = $who->cget(-text);

    #changes the buffer depending on which button was pressed
    $buff += 5 if($txt =~ /\+/);
    $buff -= 5 if($txt =~ /-/);

    #saves the file that is being worked with as "sizetemp"
    my $temp_file_1 = $file1;
    my $temp_file_2 = $file2;

    $everse = "SizeVerse1";
    $fverse = "SizeVerse2";
    $conn = "sizetemp";
    #call save blinker function
    &saveb;
    #save the redo array
    @tempredo = @redo;


    #reopens the file "sizetemp", which will now have the new buffer size
    $open = "sizetemp";
    &open2;

    #restore the old values before the resize
    $file1 = $temp_file_1;
    $file2 = $temp_file_2;
    $everse = $file1;
    $fverse = $file2;

    #reload the redo array
    @redo = @tempredo;
    
    $info = "resize complete";
}
#-----------------------------------------------------------------------------
#resize end



#This function moves from browse mode to edit mode
sub browse{
    #if in browse mode, disable all the word buttons
    if($rb_value eq 'Browse'){
	foreach(@id1){
	    $_->configure(-state,'disabled');
	}
	foreach(@id2){
	    $_->configure(-state,'disabled');
	}
    }
    #if in edit mode, enable all word buttons
    elsif($rb_value eq 'Edit'){
	foreach(@id1){
	    $_->configure(-state,'normal');
	}
	foreach(@id2){
	    $_->configure(-state,'normal');
	}
    }
}
#-----------------------------------------------------------------------------
#browse end


#This function goes to the next/previous blinker file
sub next{

    #finds which button was pressed (Prev or Next)
    my $who = $sizeframe->focusCurrent();
    
    #gets the text inside the button that was pressed
    my $txt = $who->cget(-text);    

    #if the user hit the next button
    if($txt =~ /Next/){
	#checks if there was a blinker file opened yet, if not, opens the first one
	if($blinkfile !~ /.*A[0-9]+.samp[0-9]+\.SentPair[0-9]+/){
	    $info = "No Blinker files in the history";
	    $entry1_w->bell();
	    return;
	}
	else{
	    #gets the necessary numbers from the last blinker file
	    my $A = my $samp = my $SentPair = my $temp3 = my $temp4 = $blinkfile;
	    $A =~ s/.*A([0-9]+).+/$1/; #gets the annotator number
	    $samp =~ s/.*A[0-9]+.samp([0-9]+).+/$1/; #gets the samp#
	    $SentPair =~ s/.*A[0-9]+.samp[0-9]+\.SentPair([0-9]+).*/$1/; #gets the SentPair#
	    $temp3 =~ s/^(.*)A[0-9]+.+/$1/; #this is the beginning part of the directory
	    $temp4 =~ s/^.*SentPair[0-9]+(.*)/$1/;  #checks for anything after the SentPair (.open etc)
	    

	    #Checks for the extreme cases
	    if($SentPair == $v-1){
		#if samp# is at its limit
		if($samp == $sam){
		    #if annotator is at its limit
		    if($A == $an){
			#wrap arround if last file
			$A = 1;
		    }
		    else{
			$A++;
		    }
		    #wrap around
		    $samp = 1;
		    $SentPair = 0;
		    
		    #set $sent to the new file
		    $blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
		    
		    #Check if there is an annotator for this file
		    if(!open(TEST, $sent)){
			$info = "Error opening $sent, No annotator for this file";
			$entry1_w->bell();
			return(-1);
		    }
		    close (TEST);
		    
		    #load the next file if possible
		    &openb;
		    $info = $sent." Loaded";
		    return;
		}
		#else not a total extreme case, but adjust for SentPair extreme
		else{
		    #increment samp#, wrap around SentPair#
		    $samp++;
		    $SentPair = 0;

		    #set $sent to the new file
		    $blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
		    
		    #Check if there is an annotator for this file
		    if(!open(TEST, $sent)){
			$info = "Error opening $sent, No annotator for this file";
			$entry1_w->bell();
			return(-1);
		    }
		    close (TEST);

		    #load the next file if possible
		    &openb;
		    $info = $sent." Loaded";
		    return;
		}
	    }
	    #else not an extreme case at all, just increment the SentPair
	    elsif($SentPair < $v-1 ){
		$SentPair++;

		#set $sent to the new file
		$blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
		
		#Check if there is an annotator for this file
		if(!open(TEST, $sent)){
		    $info = "Error opening $sent, No annotator for this file";
		    $entry1_w->bell();
		    return(-1);
		}
		close (TEST);
		
		#load the next file if possible
		&openb;
		$info = $sent." Loaded";
		return;
	    }
	}
	    
    }

    #Else the user hit the previous button, not next
    elsif($txt =~ /Prev/){
	#check if there was a blinker file opened yet
	if($blinkfile !~ /.*A[0-9]+.samp[0-9]+\.SentPair[0-9]+/){
	    $info = "No Blinker files in the history";
	    $entry1_w->bell();
	    return;
	}
	#if a blinker file was opened
	else{
	    #get the necessary numbers from the last opened blinker file
	    my $A = my $samp = my $SentPair = $temp3 = $temp4 = $blinkfile;
	    $A =~ s/.*A([0-9]+).+/$1/; #gets the annotator number
	    $samp =~ s/.*A[0-9]+.samp([0-9]+).+/$1/; #gets the samp#
	    $SentPair =~ s/.*A[0-9]+.samp[0-9]+\.SentPair([0-9]+).*/$1/; #gets the SentPair#
	    $temp3 =~ s/^(.*)A[0-9]+.+/$1/; #this is the beginning part of the directory
	    $temp4 =~ s/^.*SentPair[0-9]+(.*)/$1/;  #checks for anything after the SentPair (.open etc)

	    #check for extreme cases
	    if($SentPair == 0){
		#if samp# is at the lower limit
		if($samp == 1){
		    #if annotator is at lower limit
		    if($A == 1){
			#wrap around if this is the first file
			$A = $an;
		    }
		    else{
			$A--;
		    }
		    #wrap around
		    $samp = $sam;
		    $SentPair = $v-1;
		    
		    #set $sent to the new file
		    $blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
		
		    #Check if there is an annotator for this file
		    if(!open(TEST, $sent)){
			$info = "Error opening $sent, No annotator for this file";
			$entry1_w->bell();
			return(-1);
		    }
		    close (TEST);

		    #load the previous file if possible
		    &openb;
		    $info = $sent." Loaded";
		    return;
		}

		#else not a total extreme case, just adjust for SentPair extreme
		else{
		    #decrement samp#, wrap SentPair around
		    $samp--;
		    $SentPair = $v-1;
		    
		    #set $sent to the new file
		    $blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
		
		    #Check if there is an annotator for this file
		    if(!open(TEST, $sent)){
			$info = "Error opening $sent, No annotator for this file";
			$entry1_w->bell();
			return(-1);
		    }
		    close (TEST);

		    #load previous file if possible
		    &openb;
		    $info = $sent." Loaded";
		    return;
		}
	    }
	    
	    #else no extreme at all, just decrement SentPair and load
	    elsif($SentPair != 0){
		$SentPair--;
	    
		#set $sent to the new file
		$blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
		
		#Check if there is an annotator for this file
		if(!open(TEST, $sent)){
		    $info = "Error opening $sent, No annotator for this file";
		    $entry1_w->bell();
		    return(-1);
		}
		close (TEST);

		#load the previous file if possible
		&openb;
		$info = $sent." Loaded";
		return;
	    }
	}
    }
}
#-----------------------------------------------------------------------------
#next end



#This function will switch between annotators in the blinker data
sub nextan{

    #finds which button was pressed (Prev or Next)
    my $who = $sizeframe->focusCurrent();
    
    #gets the text inside the button that was pressed
    my $txt = $who->cget(-text);  

    #checks if the user hit the next annotator button
    if($txt =~ />/){
	#checks if a blinker file has been opened yet
	if($blinkfile !~ /.*A[0-9]+.samp[0-9]+\.SentPair[0-9]+/){
	    $info = "No Blinker files in the history";
	    $entry1_w->bell();
	    return;
	}

	#if a blinker file has been opened...
	else{ 
	    #get the necessary numbers from the blinker file
	    my $A = my $samp = my $SentPair = my $temp3 = my $temp4 = $blinkfile;
	    $A =~ s/.*A([0-9]+).+/$1/; #get the annotator
	    $samp =~ s/.*samp([0-9]+).+/$1/; #gets the samp#
	    $SentPair =~ s/.*SentPair([0-9]+).*/$1/; #gets the SentPair#
	    $temp3 =~ s/^(.*)A[0-9]+.+/$1/; #this is the beginning part of the directory
	    $temp4 =~ s/^.*SentPair[0-9]+(.*)/$1/;  #checks for anything after the SentPair (.open etc)
	    
	    #check for extreme case
	    if($A == $an){
		#wrap around if A = $an
		$A = 1;
	    }
	    else{
		$A++;
	    }
	    #set $sent to the new file
	    $blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;

	    #Check if there is an annotator for this file
	    if(!open(TEST, $sent)){
		$info = "Error opening $sent, No annotator for this file";
		$entry1_w->bell();
		return(-1);
	    }
	    close (TEST);

	    #load next annotator if possible
	    &openb;
	    $info = $sent." Loaded";
	    return;
	}
    }

    #else if the user hit the previous annotator button
    elsif($txt =~ /</){
	#check if a blinker file has been opened yet
	if($blinkfile !~ /.*A[0-9]+.samp[0-9]+\.SentPair[0-9]+/){
	    $info = "No Blinker files in the history";
	    $entry1_w->bell();
	    return;
	}

	#if a blinker file has been opened...
	else{ 
	    #get the necessary numbers from the blinker file
	    my $A = my $samp = my $SentPair = $temp3 = $temp4 = $blinkfile;
	    $A =~ s/.*A([0-9]+).+/$1/; #gets the annotator number
	    $samp =~ s/.*samp([0-9]+).+/$1/; #gets the samp#
	    $SentPair =~ s/.*SentPair([0-9]+).*/$1/; #gets the SentPair#
	    $temp3 =~ s/^(.*)A[0-9]+.+/$1/; #this is the beginning part of the directory
	    $temp4 =~ s/^.*SentPair[0-9]+(.*)/$1/;  #checks for anything after the SentPair (.open etc)
	    
	    #check for extreme case
	    if($A == 1){
		#wrap around if A = 1
		$A = $an;
	    }
	    else{
		$A--;
	    }
	    #set $sent to the new file
	    $blinkfile = $sent = $temp3."A".$A."/samp".$samp.".SentPair".$SentPair.$temp4;
	    
	    #Check if there is an annotator for this file
	    if(!open(TEST, $sent)){
		$info = "Error opening $sent, No annotator for this file";
		$entry1_w->bell();
		return(-1);
	    }
	    close (TEST);
	    
	    #load the previous annotator if there is one
	    &openb;
	    $info = $sent." Loaded";
	    return;
	}
    }
}
#-----------------------------------------------------------------------------
#nextan end



#This function will toggle the mode that the tool is in (Edit/Browse)
sub chmode{
    #change to Browse mode if currently in Edit mode
    if($rb_value eq 'Edit'){
	$rb[0]->invoke;
    }

    #change to Edit mode if currently in Browse mode
    elsif($rb_value eq 'Browse'){
	$rb[1]->invoke;
    }  
}
#-----------------------------------------------------------------------------
#chmode end


#This function makes a pop-up to change the data limits
sub data_pop{
    #make a toplevel widget with 3 entry boxes and save/cancel/help buttons
    $t8 = $mw->Toplevel();
    #withdraw to use different pop-up method
    $t8->withdraw();
    $t8->title("Data Limits");
    $t8->Label(-text,"Number of sub-sections per text file:")->pack(-side,'top');
    my $e1 = $t8->Entry(-textvariable,\$vtemp,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w',-fill,'x');
    $t8->Label(-text,"Number of parallel texts:")->pack(-side,'top');
    my $e2 = $t8->Entry(-textvariable,\$samtemp,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w',-fill,'x');
    $t8->Label(-text,"Number of annotators:")->pack(-side,'top');
    my $e3 = $t8->Entry(-textvariable,\$antemp,-background,"white",-takefocus,1)->pack(-side,'top',-anchor,'w',-fill,'x');
    $b_frame = $t8->Frame->pack(-side,'bottom');
    $b_frame->Button(-text,"Cancel",-background,"black",-foreground,"white",-command,sub{$t8->withdraw})->pack(-side,'right');
    $b_frame->Button(-text,"Save",-background,"black",-foreground,"white",-command,\&chdata)->pack(-side,'right');
    
    #makes the help button that opens the README and moves to the proper spot
    $b_frame->Button(
        -bitmap => 'questhead',
        -command => sub{
            &help_pop;
            #make text widget able to write to
            $help->configure(-state,'normal');
            #select the pertinent info
            $help->tagAdd("MySel","612.0","622.0 lineend");
            #moves to the right spot in the text widget
            $help->see("MySel.first");			  
            $help->configure(-state,'disabled');
    })->pack(-side,'left',-padx,15);
    

    #define hard enter callback for entry widget 3
    $e3->bind("<Return>",\&chdata);    
    $e1->focus();
    
    #makes the pop-up button appear
    $t8->Popup;
    $t8->focus();

    sub chdata{
	#checks if there are only numbers in the entry boxes
	if($vtemp !~ /^[0-9]+$/ || $samtemp !~ /^[0-9]+$/ || $antemp !~ /^[0-9]+$/){
	    $info = "Please enter valid numbers for the data values";
	    $entry1_w->bell();
	    return;
	}
	
	else{
	    #changes the default values for verse numbers,samples and annotators
	    $v = $vtemp;
	    $sam = $samtemp;
	    $an = $antemp;
	    $info = "Data values changed";
	    $t8->withdraw;
	}
    }
}
#-----------------------------------------------------------------------------
#data_pop end


#this function packs the button for next line, if it is on, removes it if it is off
sub lbyl{
    #show the button if the line-by-line button is on
    if($cb_value){
	$nl->pack(-side,'right');
	$pl->pack(-side,'right');
	
    }
    #remove the button if the line-by-line button is off
    else{
	$pl->pack('forget');
	$nl->pack('forget');
    }
}
#-----------------------------------------------------------------------------
#lbyl end



#this function pops up a browsing window so someone can find a file in their file structure
sub find{
    #make a SimpleFileSelect widget
    $top = $mw->$SimpleFileSelect();

    #save the selected file in $file
    if($top->can('Show')){
	$file = $top->Show;
    }
    else{
	#make a toplevel widget
	$t9 = $mw->Toplevel();
	$top2 = $t9->Label(-text,"SimpleFileSelect module not installed.\nFind option not available.");
	$top2->pack;
	$t9->Button(-text,"Close",-command,sub{$t9->withdraw;})->pack();
	return;
    }
    #make a toplevel widget
    $t9 = $mw->Toplevel();

    #withdraw for differnt pop-up method
    $t9->withdraw();
    $t9->title("File Usage");
    $t9->Label(-text,"$file:\nWhat type of file is this?")->pack();

    #make buttons for the possible file types
    foreach(("Source Text (left side)", "Target Text (right side)")){
	
	$t9->Radiobutton(-text,$_,-value,$_,-variable,\$f_value,
			 -background,'black',-foreground,'white',
			 -indicatoron,0)->pack(-side,'top',-pady,5);
    }
    
    #make load/cancel buttons
    my $tframe = $t9->Frame->pack(-side,'bottom',-fill,'x');
    $tframe->Button(-text,"Load",-command,\&load_found,-activebackground,'blue')->pack(-side,'left',-anchor,'w');
    $tframe->Button(-text,"Cancel",-command,sub{$t9->withdraw;},-activebackground,'blue')->pack(-side,'left',-anchor,'w');

    #Makes toplevel pop-up
    $t9->Popup;
    $t9->focus();
    
    sub load_found{
	#load file 1
	if($f_value =~ /Source Text/){
	    #set variable and load file 1
	    $file1 = $file;
	    &load_1;
	    $t9->withdraw;
	    $f_value = "";
	}
	#load file 2
	elsif($f_value =~ /Target Text/){
	    #set variable and load file 2
	    $file2 = $file;
	    &load_2;
	    $t9->withdraw;
	    $f_value = "";
	}
	
    }
}
#-----------------------------------------------------------------------------
#find end


#This function is called by open_pop if the user needs to find an alpaco file
sub find_al{
    #removes the old pop-up if it exists
    $t4->withdraw if(Exists($t4));

    #make a SimpleFileSelect widget
    $top = $mw->$SimpleFileSelect();
    
    #save the selected file in $file
    if($top->can('Show')){
	$file = $top->Show;
    }
    else{
	#make a toplevel widget
	$t9 = $mw->Toplevel();
	$top2 = $t9->Label(-text,"SimpleFileSelect module not installed.\nFind option not available.");
	$top2->pack;
	$t9->Button(-text,"Close",-command,sub{$t9->withdraw;})->pack();
	return;
    }
    
    #load an Alpaco File
    #set this variable to the file the user found
    $open = $file;
    #open Alpaco file function
    &open2;
    
}
#-----------------------------------------------------------------------------
#find_al end



#This function will display the sentences in a text widget popup
sub show_sentences{

#make the toplevel widget with the text widget inside it
$t10 = $mw->Toplevel();

#withdraw for different pop-up method
$t10->withdraw();
$t10->title("Verse Display");
$sentences = $t10->Scrolled("Text")->pack();

#insert the sentences into the text widget
$sentences->insert("end",$sentence1."\n");
$sentences->insert("end","=" x 80);
$sentences->insert("end","\n\n".$sentence2."\n\n");

#disable the text widget for read-only status
$sentences->configure(-state,'disabled');

#make a close button, and insert it into the text widget
my $close = $t10->Button(-text,"Close",-background,"blue",-foreground,"white",-command,sub{$t10->withdraw});
$sentences->windowCreate('end',-window,$close);

#makes toplevel pop-up
$t10->Popup;
$t10->focus();

return;
}
#-----------------------------------------------------------------------------
#show_sentences end


__END__



=head1 NAME

alpaco.pl - Aligner for Paralell corpora

=head1 SYNOPSIS

perl alpaco.pl

=head1 DESCRIPTION

Aligner for Parallel Corpora (Alpaco) is a program that is designed to 
align bilingual parallel texts.  If two files are known to be translations 
of each other, Alpaco can be used to manually align them and save the 
alignments for future reference.  

Alpaco can take the following as input:  raw text files, Blinker data 
(explained in section 3 of the README), and previously aligned text files 
(Alpaco format).  It also has the ability to read in raw text files line-by-
line for easier use with large text files.  This gets a bit more complicated 
with the naming scheme, which is explained in the README. 

=head1 AUTHOR

Alpaco was written by Brian Rassier <rass0028@d.umn.edu> as a research 
project for Dr. Ted Pedersen <tpederse@d.umn.edu>


=head1 SEE ALSO

For information about naming standards, file types and general Alpaco usage
please see the README that was distributed with the Alpaco package.

=cut

    
