Vars
====

Find variables and dangerous function in PHP sources.


Install
====

<b>On debian/Ubuntu:</b>

sudo gem install ruport

Usage
====

Start scan with:

./vars.rb -d [path] [options]

The options are:

-d or --directory = Directory which contains the .php files.<br/ >
-v or --verbose = Run in verbose mode.<br/ >
-f or --function = Find dangerous functions.<br/ >
-s or --search = Search specific variables, function or variable contained in the function.<br/ >
-l or --log = Specific the log file to save the scan result.<br/ >

If you don't use the log file to save the data, this will be shown in the terminal with table-style.
If you save data, the script ask you if want open the log in this moment. Press [ENTER] or Y to view the file with your default browser, or n to refuse.

Example
====

./vars.rb -d test

Open all files .php in the direcotory named "test" and show the information if variables in terminal.
<br><br>

./vars.rb -d test -s lol -l a.html

Open all files .php in the directory named "test", find the variable "lol" and save data in "a.html".
<br><br>

./vars.rb -d test -f

Open all files .php in the directory named "test" and find all dangerous function.
<br><br>

./vars.rb -d test -f -s lol

Open all files.php in the directory named "test" and find all dangerous functions that contain the string "lol".
