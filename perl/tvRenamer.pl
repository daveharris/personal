#!/usr/bin/perl

# A script that renames files based on the parent directory.  It contacts www.tvrage.com and gets the episode listing to get the episode names.  It will ask you if you want to rename the file before doing so.  It finds the episode number from the filename.

# It takes in either a filename to rename or '*' to specify all files in a directory.  By default it will look up the latest season, but this can be specified by specifying the season number with -s.

use strict;
use LWP::Simple;
use Cwd;

my ($numArgs, $fileIndex, $show, $showName, $season, $originalPath, $path, $url, @content, @contentLine, @files, $file, $fileToRename, $num, $title, $newName, $search, $fileName, @fileName, $searchString, $queryString, $userInput, $yesToAll);

#open(FILE, "../ep_list.tmp") or die("Unable to open file");

$numArgs = $#ARGV+1;
$fileIndex = 0;

#for(my $i=0; $i < $numArgs; $i++) {
#  print("ARGV[$i]:$ARGV[$i]\n");
#}

&main();

sub main {
  $yesToAll = "n";
  $originalPath = getcwd();
  &handleArgs();
  &getContent();
  &run();
}


sub handleArgs {
  if($numArgs == 0) {
  print("Usage: tvRenamer [-s] [-p] {filename(s)/*} \nto rename all/specified files according to parent directory\n");
  exit();
  }
  
  # If a specific (not the latest) season is passed
  for(my $i=0; $i < $numArgs; $i++) {
    if($ARGV[$i] =~ "-s") {
      $season = $ARGV[$i+1];
      $fileIndex+=2;
    }
    if($ARGV[$i] =~ "-p") {
      $path = $ARGV[$i+1];
      $fileIndex+=2;
    }
  }
  if($path) {
    chdir($path);
  }
}


sub getContent {
  # Get the showname from the parent/specified dir
  $show = getcwd();
  $show =~ s/.*\/(.*)/\1/;
  
  #Change back to the original path to rename the files
  chdir($originalPath);
  
  # create the url and download the ep listing
  $showName = $show;
  $showName =~ s/\ /_/g;
  $showName =~ s/\'//g;
  $url = "http://www.tvrage.com/".$showName."/episode_list/".$season;
  @content = split("\n", get($url));
  #@content = <FILE>;
}


sub run {
  for(my $i=$fileIndex; $i < $numArgs; $i++) {
    @files[$i-$fileIndex] = $ARGV[$i];
  }
  
  # Recurse through the selected files and call renameFile() on them
  foreach $file (@files) {
    &renameFile($file);  
  }
}


sub renameFile {
  $fileToRename = $_[0];
  
  $num = $fileToRename;
  $num =~ s/.*(\d\d).*/\1/;

  # find just the episode lines
  $searchString = "b2.*episodes.*x$num";
  @contentLine = grep(/$searchString/, @content);
  chomp(@contentLine);
  
  $title = @contentLine[0];
  $title =~ s/.*\'>(.*)<\/a>.*/\1/;
  
  $num = @contentLine[0];
  $num =~ s/.*(.x..)\'>.*/\1/;
  
  $newName = $show . " [" . $num . "] " . $title . ".avi";
  if($yesToAll =~ "n") {
    $queryString = "Rename \'$fileToRename\' --> $newName\'? (y/n/A[ll]/q[uit]) ";
    print($queryString);
    chomp($userInput = <STDIN>);
  }
  
  if($userInput =~ "y" || $yesToAll =~ "y") {
    rename($fileToRename, $newName);
  }
  elsif($userInput =~ "A") {
    rename($fileToRename, $newName);
    $yesToAll = "y";
  }
  elsif($userInput =~ "q") {
    exit();
  }    
}

close(FILE);
