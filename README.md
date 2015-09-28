```
                  				   ALPACO

                         Aligner for Parallel Corpora
                         ============================
                        Version 0.3 Copyright (C) 2003
                       Brian Rassier, rass0028@d.umn.edu
                       Ted Pedersen, tpederse@umn.edu
                        University of Minnesota, Duluth
		
		                   Released January 27, 2003

          		 http://www.d.umn.edu/~tpederse/parallel.html


1. Introduction:
----------------

Alpaco (Aligner for Parallel Corpora) is a program that is designed to 
align parallel texts.  If two files are known to be translations 
of each other, Alpaco can be used to manually align them (word-by-word or
phrase-by-phrase) and save the alignments for future reference.  

Alpaco can take the following as input:  raw text files, Blinker data 
(explained in section 3), and previously aligned text files (Alpaco format).  
Alpaco format is basically a superset of the Blinker data, which is explained
in sections 3 and 4.  Alpaco also has the ability to read in raw text files 
line-by-line for easier use with large text files.  This gets a bit more 
complicated with the naming scheme, which is explained later in the README
(section 5 and 6.1.2).

This README continues with brief notes about Alpaco, and how a user would 
typically use this alignment tool.  



2. Packages Needed:
-------------------

Alpaco was written using perl  v5.6 and Tk v800.023.  Any versions at this 
level or higher will work with Alpaco.  Any lesser versions may work, but 
they have not been tested.

Alpaco uses two modules which were necessary for making the tool easier for 
the user.  The modules necessary are Tk:HistEntry.pm (version 0.37 or higher)
and Tk:SimpleFileSelect.pm (version 0.66 or higher).   They can both be found
at: http://www.perl.com/CPAN/modules/by-module/Tk/.
They are both distributed with Readme files, which will explain the 
installation.  To see if they were installed correctly, make a simple perl/Tk
script which contains the following:

#!/usr/local/bin/perl
use Tk;
use Tk::HistEntry;
use Tk::SimpleFileSelect;

my $mw = MainWindow->new;
$e1 = $mw->HistEntry(-textvariable,\$file1, -background,"white", -takefocus,1)->pack(-side,'top', -anchor,'w');
$mw->Button(-text,'Find A File',-command,\&find)->pack(-side,'bottom');
$mw->Button(-text,'Close',-command,sub{exit;})->pack(-side,'bottom');

MainLoop;

sub find{
$top = $mw->SimpleFileSelect;
$found = $top->Show;
$file1 = $found;
$e1->historyAdd($found);
}

This script will make a simple interface that uses both modules.  If 
everything is working properly, this program will work also.  If there are 
errors, there may be a problem with the installation of the modules.  In that
case, try visiting www.perl.org or www.cpan.org. 



3. Blinker Data:
----------------

There was a similar project done at NYU, which was named the Blinker.  The 
Alpaco project is based on the Blinker project.  Information about the 
Blinker research, and the Blinker data is available at: 
http://www.cs.nyu.edu/cs/projects/proteus/blinker. The file structure to 
Alpaco is based on the Blinker system, and Alpaco can also read and edit 
the Blinker data.  The Blinker data is stored in a format of two columns of 
numbers.  Each column of numbers refers to the word number in the respective 
text.  The numbers in each row are alignments of each other.  A simple 
example will make this more clear.  A sample blinker file may consist of two
columns as follows:
1 4
3 3
2 1
0 2
The first column would correspond to words in the source text, and the second 
column would correspond to words in the target text.  The connections would be
as follows: 

- The first word in the source text would be connected to the fourth word in 
  the target text.
- The third word in the source text would be connected to the third word in the
  target text.
- The second word in the source text would be connected to the first word in 
  the target text.
- The second word in the target text would have no connection to the source 
  text (Null Connection).

The last alignment is a bit different. If there is a zero in this format, it 
indicates a null connection.  This means there is no word that is an alignment 
in the other text.  For example in row four, it shows that word two of the 
target has no alignment to the source.  Null connections are explained a bit 
more in sections 4 and section 6.5.2.
 
There was a complex naming scheme to the Blinker data, which is related to 
Alpaco's usage in the file blinker_data.txt included with this package.  It 
is also explained next.

The Blinker was used to align verses of the English Bible to the French 
Bible.  There were seven annotators that worked with this tool, and they 
aligned 25 files with 10 verses in each file.  The 10 verses are broken into
sub-sections of the larger text file, and are separated by a newline character.
The aligned files are named in the format samp*.SentPair? where the 
corresponding verse number is calculated by: 

verse # = (samp# - 1) * 10 + SentPair# + 1  

This is the equation that is referred to throughout the README.  The parallel 
text files are named EN.sample.* for English and FR.sample.* for French.  Here 
is an example of some Blinker data from the given web-site.  These samples, and
the 10 alignment files are included with the Alpaco package.  The 10 
alignment files are in the A1 directory.  They can be opened as Alpaco files 
to see a typical alignment.

EN.sample.1 (only verse one (sub-section one) is shown here)
-----------
After all , if you were cut out of an olive tree that is wild by nature , and contrary to nature were grafted into a cultivated olive tree , how much more readily will these , the natural branches , be grafted into their own olive tree !

FR.sample.1 (only verse one(sub-section one) is shown here)
-----------
Si toi , tu as été coupé de le olivier naturellement sauvage , et enté contrairement à ta nature sur le olivier franc , à plus forte raison eux seront - ils entés selon leur nature sur leur propre olivier .


A1/samp1.SentPair0 ---> (connections for the first Annotator, for the 
first verse of the given text samples)
-------------------------
4 1
5 2
5 4
7 7
9 8
8 8
10 9
12 10
11 10
16 11
17 11
13 12
14 12
15 12
18 13
19 14
24 15
20 16
21 17
22 18
22 19
23 5
23 6
6 5
6 6
25 20
26 21
28 22
29 22
27 23
30 24
1 0
2 0
3 3
49 41
47 40
48 40
46 39
45 38
44 37
43 33
32 26
33 26
34 27
34 28
36 29
35 30
42 30
39 34
39 35
39 36
40 32
37 0
38 0
41 0
31 0
0 31
0 25
**These are all the connections from Annotator 1 for the verses (sub-sections) 
found by the equation given above.  The order to these numbers does not 
matter, it is just in the order that the alignments were made.  This file
shows an alignment of the 4th word in the English text to the 1st word in the
French text etc.  There are cases of a single word aligning to multiple words 
in this file. For example, word 22 in English (left column) is aligned to two 
words in French (right column), the 18th and 19th words.  Multiple words in one
language can be aligned to multiple words in the other (phrase-by-phrase 
alignments), but this file does not have an example of this.  The zeros in each
column, as explained earlier, represent that there is no alignment for that 
word to the other file.  These alignments are much easier seen when the file is
loaded into Alpaco.  To view this particular alignment in Alpaco, click the 
"file" menu, then the "Open an Alpaco File" option.  In the box that appears, 
type "A1/samp1.SentPair0".  This will open the files from above, and load the 
alignments for viewing/editing. 



4. Alpaco data:
---------------

As stated earlier, Alpaco data is stored much like the Blinker data.  The 
Blinker files are a subset of the Alpaco files.  This just means that Alpaco
can use the blinker files explained earlier, plus one other type.  The second
type is identical to Blinker files, except it has a different first line. The 
first line consists of two file names.  These lines are then loaded so an 
equation is not needed to find the appropriate files.  This file type is very
useful if text files are aligned as a whole.  The file naming then becomes 
much simpler, which is explained more in section 5.  After this first line,
there are two columns of numbers which are used the exact same way as explained
earlier.  Another note to make is that if there is ever a zero in a column, 
it means that the opposite column has no connection, or a null connection (as 
explained earlier).  An example of a typical Alpaco file is as follows:
file1 file2
1 1
2 4
3 2
0 3

In this file, there would be two files named file1 and file2.  They would 
have the following manual alignments:

- The first word in file1 would be connected to the first word in file2.
- The second word in file1 would be connected to the fourth word in file2.
- The third word in file1 would be connected to the second word in file2
- The third word in file2 would have no connection to file1 (Null Connection).

These may not be the only words in the files, but they are the only words 
that have been manually aligned.

There is one case where Alpaco files are not saved with file names at the top.
Alpaco can be used to break up text files into sub-sections by newline 
characters.   This way the alignments can be made on a smaller scale (explained
more in section 6).  In this case, Alpaco will use an equation similar to the 
Blinker, so names are not stored with the connections.  The Alpaco equation is:

sub-section # = (samp# - 1) * sub-sections + SentPair# + 1  

The only difference between this equation and the Blinker equation is that 
there is a variable (sub-sections) in the place of the number 10 in the Blinker
equation.  This is for flexibility so that users can break files up into any 
number of sub-sections.  If files are not broken up into 10 sub-sections then 
the data limits must be changed, which is explained in more detail in section 
6.12.  Throughout the Readme, if files are said to be in the "Blinker" format, 
it just means that the naming scheme follows this equation or the similar 
Blinker equation given earlier. 

Alpaco adjusts for the two types of files when files are opened.  It looks for 
file names at the top of the Alpaco file, but if they are not found it tries 
loading with the given equation.  If Alpaco is used with the equation, naming 
standards for the files are very strict, which is explained in the next 
section.  This is so the equation can be used properly.  This format is very 
useful when looking at connections, because users can skip through to the next 
file/annotator by simply pressing a button.  This means that they do not have 
to type the whole file path in order to open the next file.



5. File Naming Standards:
-------------------------

There are two different ways Alpaco can be used, as far as file naming is 
concerned.  When deciding which naming standard to choose, users should 
determine if there will be a large amount of data to be aligned, or if just a 
few files will be aligned.  The choice is up to the user, but both standards 
will be explained next.  Throughout this section it is said that parallel text 
files are broken up into "sub-sections".  This simply means that there is a 
newline character that separates sections of the larger text file.  These 
sub-sections must be made by the user, and are assumed to represent alignments 
at a sentence level.  This means that the sub-sections are known to be 
alignments of each other, and Alpaco will help to make alignments at the 
word/phrase level.


5.1. File Naming with the Alpaco Format
---------------------------------------
This format is very useful if there will only be small amounts of data/files
to be aligned.  Files can be aligned as a whole or line-by line in this 
format.  In order to save in the line-by-line format with this naming scheme,
users must save with the "Save Current Work to File" option from the
file menu (see section 6.3.2).  In the non-line-by-line format, simply use the 
"Save an Alpaco File" option from the file menu.  Users will then be prompted 
for a name for the file.  In both of these situations the tool will take the 
names of the two text files, insert them at the top of the saved Alpaco file, 
then save the connections after the file names.  This will ensure that the user
won't have to keep track of a naming scheme.  The user can name the files what 
they choose, and load/edit them by that name.


5.2. File Naming With the Blinker Format
----------------------------------------
This format is helpful when large amounts of data/files are needed.  The 
format is very strict, but if followed can be very beneficial.  

A large benefit for this format is that large files can be broken up to be 
aligned in smaller sections.  This must be done in line-by-line mode.  When in 
line-by-line mode, the tool will look for a newline character, and load 
segments separated by this character.  The input files must be split up by 
these newlines by the user before the file is loaded.  This way the user can 
separate the files how they wish.  A good example of how to break up the files 
is seen in the Blinker data included with Alpaco (EN.sample.1 and FR.sample.1).
  
The first naming stipulation is that of all the following items are in the same
directory:
    - annotators' directories
    - parallel text files
The annotators' directories must be named in the format A# with the # being 
the number of annotator it is.  If only one annotator is used the user will 
simply have one directory named A1. 

In these directories will be the files with the connection information listed
previously.  The format listed previously holds here too.  They will be named
samp*.SentPair? where the samp number is the text file associated with this 
alignment, and SentPair number is the sub-section number (starting at 0) 
within this text file.

The default data values for Alpaco is having 7 annotators (7 directories named
A1 - A7), 25 text samples (25 different prefixes named similar to 
A1/samp1.SentPair? - A1/samp25.SentPair? for all 7 annotators), and 10 
sub-sections per text sample (each text file is separated by 10 newlines, thus 
broken into 10 smaller alignments. Naming follows: A1/samp1.SentPair0 - A1/samp1.SentPair9).  These defaults are from the Blinker data, so Alpaco is set up to
read/edit Blinker data by default.  These data limits can be changed by 
choosing "Change Data Limits" from Alpaco's options menu.  This must be done 
every time Alpaco starts if the data limits differ from Blinker's standards.  
This is explained further in section 6.

The parallel text files must be in the main directory, but outside the 
annotators' directories.  They must be separated by the two languages that are 
represented.  One language must be named EN.sample.?, and the other must be
FR.sample.?. These question marks must match up with parallel text files 
being the same.  The default number for this, as stated earlier is 25 files. 
(EN.sample.1 - EN.sample.25 and FR.sample.1 - FR.sample.25).  This data limit
can be changed the same way as listed previously, and is explained further in
section 6.

Here is an example of a naming standard.  There is one directory, in this 
example named test_data.  In this directory should be: annotators' directories
and parallel text files.  In this example, if there were 2 annotators, 
there would be 2 directories named A1 and A2.  If there were 10 parallel text 
files, they would be within the test_data directory, and named 
test_data/EN.sample.1 - test_data/EN.sample.10 and test_data/FR.sample.1 - 
test_data/FR.sample.10.  Within the annotators' folders would be the aligned 
files.  If each text sample was separated into 3 sub-sections, then the aligned
files would be named test_data/A1/samp1.SentPair0 - 
test_data/A1/samp10.SentPair2.  The same would be done for the A2 directory.  
With this example, the files to be loaded are the SentPair files (aligned 
files).  Simply choose "Open an Alpaco File" from the file menu and enter a 
file similar to test_data/A1/samp1.SentPair0.  The tool will then find the 
correct text and connection information, and load it.

Another example of this standard is with the included files.  EN.sample.1 and
FR.sample.1 are included, which are Blinker sample texts.  These text samples 
are broken up into 10 sub-sections, so in A1 there are 10 example alignment 
files (samp1.SentPair0 - samp1.SentPair1).  The files in the A1 directory can 
actually be opened as Alpaco files, and then the alignments can be seen/edited.

Although this is a very strict naming strategy, it must be done for the Blinker
equation to be used.  It is also a must for the benefits that come from it 
(next/previous file and annotator etc).  These benefits are further explained
in section 6.



6. Alpaco Usage:
----------------

After the file naming standards are learned, the rest of Alpaco is very simple
to use.  This section will go through the main abilities Alpaco has, and the 
things a typical user would do with Alpaco.


6.1. Loading Raw Text Files 
---------------------------
Loading raw text files is a great way to start learning the Alpaco tool.  This
is also the main way that alignments can be made with Alpaco. The other way 
alignments can be made is by loading previously aligned files, and editing
them.  The second option is explained later in this section.  If raw text 
files are used, Alpaco considers tokens as anything separated by a space.  If
punctuation, or anything else is to be considered as its own token, the file
must be separated in this fashion before loading into Alpaco.  Included in 
this package is a helper tool that can separate these tokens for a user.  See
section 7 for more information about this helper tool.

6.1.1. Loading Raw Text Files as a Whole
----------------------------------------
Loading a raw text file as a whole is very simple.  Just type in the file name
in the entry box (for source or target), and press enter.  The term source 
and target files are used occasionally with Alpaco.  The source file is on 
the left side of the interface, and the target file is on the right.  Once 
source and target texts are loaded, the alignment process can begin.

6.1.2. Loading Raw Text Files Line-by-Line
------------------------------------------
Loading text files line-by-line is a little more complicated. First the 
option must be enabled by pressing the button to the right of the file entry
boxes.  Then files can be loaded exactly like a whole file, but it will only
read one line at a time (separated by a newline character).  Files can be 
saved in the Blinker format by saving as an Alpaco file.  The strict 
naming standards must be followed in this form, so name the files 
accordingly.  Alignments can also be saved in the Alpaco format in line-by-line
mode.  To do this the user must choose the "Save Current Work to File" option.
This will allow users to enter separate file names for the current lines of
text that they are aligning.  Alpaco will then save these file names at the top
of the alignment file.  This way Alpaco doesn't need to use the equation to 
find the text associated with the alignment.


6.2. Opening an Alpaco File
---------------------------
There are two types of Alpaco files.  One which is exactly like the Blinker 
files and will use the Blinker equation to find the associated text files, and 
another that is similar to Blinker files, only it lists the text file names
at the top, before the alignment information.  Both types, if saved and named 
correctly, can be loaded by selecting the "Open an Alpaco File" from the file 
menu (or use the shortcut by pressing Ctrl + o).  Alpaco will find the 
associated files, and load the connections.  Then the user can view the 
alignments, or edit them where needed.

There is also a find button when loading an Alpaco file.  If the user doesn't
know where the file is saved, they can press this button.  A window will pop
up with the current directory information in it.  The user can find the Alpaco
file that is desired, and the tool will load it once the file is accepted.


6.3. Saving an Alpaco File
--------------------------
There are two ways to save an Alpaco file.  One is just by giving a name for
it, in which case Alpaco has the necessary information to retrieve the files
for this alignment.  The other way is by specifying filenames, then the name
for the Alpaco file.  Both situations are explained next.

6.3.1. "Save an Alpaco File" 
----------------------------
This option is used when Alpaco knows how to get the necessary files for the
alignment.  An example of this use is when a whole file is aligned, and the
user wants to save with the more simple naming standard (see section 5).  
This will load the filenames given at the top of the file, and then load the
alignments.  The other time this option is used is when files are aligned
line-by-line, and the user wants to save with the equation.  In this case the 
user must save according to the naming standards in section 5.2.  Then Alpaco
will be able to find the needed files using the Blinker equation, and it only 
needs the name of the actual Alpaco file. 

6.3.2. "Save Current Work to File"
-----------------------------------
This option is used in two different situations.  The first is if there is a 
file that has been saved with the Blinker format, and the user wants to 
change it over to the Alpaco format (see section 5).  Then simply load the file
and select this option from the file menu.  The user will have to enter two 
file names for the text files, and a name for the Alpaco file.  The Alpaco file
will no longer need the equation, because it made new files for the current 
text, and will record these file names at the top of the Alpaco file.  The 
second way to use this option is if a user is aligning line-by-line, and wants 
to save without the naming standards explained in section 5.2.  Then the user 
must give names for the two separate lines from the larger file, and Alpaco 
will save them as their own files.  Then give a name for the Alpaco file, and 
the tool will access the files in this format instead of with the Blinker 
equation.


6.4. Edit/Browse mode
---------------------
These two modes will change whether or not the user has the ability to change
the alignment data.  Browse mode will show the alignments, but won't allow 
changes to the data.  Edit mode will show the alignments, and will allow the
user to change the data.  Please use caution in the Edit mode, because 
alignment information can be lost or altered.  The mode can be changed by 
clicking on the desired button on the interface, or by selecting "Change Mode" 
from the options menu.  Browse mode is the default when Alpaco is started.


6.5 Making Connections
----------------------
There are two different kind of connections, which are regular connections,
and null connections.  Both are explained here.

6.5.1 Regular Connections
-------------------------
This is used when there is an alignment that should be made between word(s) 
in the source text to word(s) in the target text. To make the alignment 
Alpaco must be in edit mode.  If the tool is in edit mode, simply click the 
word(s) in the source list along with the word(s) in the target list.  The 
words should change color, indicating that they were selected.  Then hit the 
Connect button on the interface, or choose connect from the options menu.  
There is also a shortcut, which is dependent on the mouse being used.  Either 
hit the right mouse button, or button 1 + 2, which will also make the 
connection.  There is also a keyboard related shortcut, which can be done by  
pressing Ctrl+c to make the connection.  Lines will be drawn to the aligned 
words, indicating the connection.  The words will also change color, to help 
indicate which words have not been aligned yet.  When a file is saved, the 
connections will be saved with it.

6.5.2. Null Connections
-----------------------
This option is used when there are word(s) in one file that have no matches
in the other file.  To make a null connection, Alpaco must also be in edit
mode.  Then simply select the word(s) with no match, and they will change 
color indicating their selection.  Then hit the Null Connect button, or 
choose Null Connect from the options menu.  There is a shortcut  for this 
option also.  When the correct words are selected, press Ctrl + n, and the
null connection will be done.  These null connections will be indicated by a
change in color.  If a word has a null connection, it will turn black, just 
like the null connect button itself.  When a file is saved, the null 
connections will also be saved with it.


6.6. Undo and Redraw Connections
--------------------------------
Once connections are drawn, they are not necessarily permanent.  They can
be undone in a few different ways.  The undone connections can also be 
redrawn.

6.6.1. Undoing a Connection
---------------------------
There are three different ways to undo connections, which make undoing them
much more convenient.  All three can be done the same way, by pressing the 
Undo button, by selecting Undo Connection from the options menu, or using the 
shortcut.  The shortcut is done by pressing Ctrl + u.  

The three ways to undo differ by how many words are selected.  If two words 
are selected (one from the target and one from the source), Alpaco will look 
for a single connection between the two words, and remove it if it exists.  
This is helpful if only one connection needs to be removed, but words have 
multiple connections associated with them.  If only one word is selected before
an undo, then all the connections associated with that word will be removed.  
This is helpful if a word is aligned poorly, and the user just wants to start 
over with its alignment.  The final way to undo a connection is by selecting 
zero words.  This will undo the last connection that was done, one alignment at
a time.  This is useful if there were some recent mistakes that were made. 

6.6.2. Redrawing a Connection
-----------------------------
If a connection is undone, Alpaco will remember them until a new file is 
loaded, the files/connections are cleared, or Alpaco is exited.  To redraw an 
undone move, simply press the Redraw button on the interface, or select 
"Redraw Connection" from the options menu.  This option will redraw a 
connection, one line at a time, until all the undone connections are redrawn.


6.7. View Sentences
-------------------
This option is very helpful when making alignments.  It helps sometimes to 
read the sentences that are to be aligned, which is what this option was made
for.  To view the sentences, select "View Sentences" from the options menu.


6.8. Clear Connections/All
--------------------------
The first of these options, Clear Connections, is helpful if the file that is
being aligned is aligned very poorly.  This way the connections that have been 
made are removed, yet the files can still be worked on.  This will start the 
aligning process from the beginning with the two files.  To clear the 
connections, choose "Clear Connections" from the file menu.

The second option, Clear All, is used when the user wants to start from
scratch.  This will remove all the connections, and the files that were being 
worked with.  To clear the entry completely, choose the "Clear All" 
choice from the file menu.


6.9. Finding Text Files
-----------------------
This choice is very helpful if the user is not very familiar with their files
and file structures.  For this option, the user must have the SimpleFileSelect
module installed (see section 2).  To find a text file, choose "Find Text 
Files" from the file menu.  A window will appear with the current directory 
information in it.  The user can then browse the directories to look for a file
to use.  Once a file is chosen, press the accept button.  Another window will 
pop up. This window will give choices of how to use the found file.  Choose if 
it is to be used for the source (left) or target (right).  These options will 
open the file just as if the regular open functions were used in its place.


6.10. Resizing
--------------
This option can be useful if many connections are in a small area, and it is 
difficult to see.  It is best used in browse mode only. This is because 
resizing can change the files being used to temporary sizing files, thus 
confusing the saving process.  To resize, simply click on the + or - sign by
the "Resize" section on the right portion of the interface.  This will 
add or reduce the space between the words, in the vertical direction.


6.11. Next/Previous File and Annotator
--------------------------------------
These options are available if the more strict naming standards are used. 
These options are a great benefit that comes from the pain of the strict 
naming standards. For example, if a user was looking at the Blinker data set,
they could go to the next/previous file by pressing the respective button
on the interface.  They can also see how other annotators aligned the text by 
pressing the next/previous annotator button.  These options are only available
once a file saved with the Blinker format has been opened.  Buttons for these 
options will appear in this situation. 


6.12. Change Data Limits
------------------------
If a different data set is used than the Blinker standards, then this option
is a must.  The defaults for Alpaco are seven data annotators, 25 parallel 
texts, and 10 sub-sections per text file(An explanation of a file and its 
sub-sections are given in section 5).  If a data set has different limits than 
this, then they can be changed.  Choose the "Change Data Limits" choice from
the options menu.  In the corresponding entry boxes enter the new data limits
for: Number of sub-sections per text file, Number of parallel texts, and Number
of annotators.  This option must be done every time Alpaco starts, if limits 
are to be used differently then the defaults.



7. Alpaco_helper.pl:
--------------------

Included in the Alpaco package is alpaco_helper.pl.  Alpaco considers tokens
as anything separated by a space in the input file, and many times the text 
is not prepared this way.  Many corpora alignments need to have punctuation 
and other sequences to be considered their own tokens, and the text may not 
have spaces to separate these sequences.  This is where Alpaco_Helper.pl 
comes in.  It is a simple text editor that can open files, and separate 
different sequences of characters given by the user.  It will separate the 
character sequences by a space, then the user can save the file as desired.  
This way the text is prepared to load into Alpaco, and aligned how the user
desires.

To split up a file, first load it into into the alpaco_helper.  To do this
simply type the name into the entry box and press enter, or select the "Open
Text File" option from the file menu.  Then to split up the file by sequences
of characters, select "Split up Tokens" from the options menu.  A window will
pop up.  In the entry box in this window, enter the sequences of characters 
that should be considered their own tokens.  They must be entered with a 
space between them in the entry box.  For example, if a user wanted question 
marks, quotation marks, and exclamation points to be their own tokens, type
{? " !} in the entry box (without the curly braces).  The file will then 
show the change with spaces separating these sequences.  Then save the file
as desired, and it is more prepared for aligning with Alpaco.  alpaco_helper
has a default splitting rule, just so users can see an example.  



8. Known Problems / Future Enhancements:
----------------------------------------

* When saving Alpaco files in the line-by-line format, the user still has to
keep track of the naming standard.  Because this naming standard is very 
strict, and may cause confusion, we plan on enabling the tool to save 
automatically.  Alpaco will be able to come up with the correct file name
depending on where the user is in the input files.  This will make the tool
much more user friendly in later releases.  

* If large files are loaded into Alpaco, memory usage can become a problem.  
The tool itself takes about 10MB to run, and the more options are used, the 
more memory it needs.  Also, each word in the file is it's own button.  This 
means that a 10,000 word file loaded as a whole will create 10,000 buttons.
These buttons have many options, and need memory to use.  This will slow down
the use of the tool in some cases, depending on the file size and how much 
memory is available.  If the larger files are broken up into smaller sections,
the tool should have no memory issues.  Our tests have shown that Alpaco takes
roughly 3MB per 2,000 words loaded into it.  

* Because of the last problem of memory usage, there may be a new design 
possibility in the future.  The alternative design idea that we have includes
using text in the place of the buttons for each word.  This may be less user
friendly, but with larger files it would be much more convenient with respect
to the memory issue.    

9. Acknowlegements
------------------

This work has been partially supported by a National Science Foundation 
Faculty Early CAREER Development award (#0092784) and by a grant from the  
Undergraduate Research Opportunities Program (UROP) of the University of 
Minnesota.  

Copying:
--------
This program package is free software; you can redistribute it and/or modify 
it under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT 
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more 
details.

You should have received a copy of the GNU General Public License along with 
this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
Place - Suite 330, Boston, MA  02111-1307, USA.

Note: The text of the GNU General Public License is provided in the file 
GPL.txt that you should have received with this distribution. 
```
