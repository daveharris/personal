#!/usr/bin/perl

use Switch;

#open(FILEWRITE, "> ~/code/perl/debug.txt");

$fullPath = $ARGV[0];
$title = $ARGV[1];

($slash,$D,$mnt,$podcast,$podcastName,$filename) = split '/', $fullPath;
$dir = join('/', $slash,$D,$mnt,$podcast,$podcastName);
chdir $dir;

$title =~ s/\`/\'/g;

switch($podcastName) {
  case /Diggnation/  {diggnation();}
  case /Discourse/   {ocdiscourse();}  
  case /FLOSS/       {floss();}
  case /Jay/         {jaynjack();}
  case /LugRadio/    {lugRadio();}
  case /Official/    {officialLostPodcast();}
  case /Security/    {securityNow();}
  case /TECH/        {twit();}
  case /Windows/     {windowsWeekly();}
}

sub diggnation() {
  $number = $filename;
  $number =~ s/.*--00(..).*/\1/i;
  $title = 'Diggnation ' . $number;

  write_tag("Diggnation");
  rename($filename, "$title.mp3");
  finishUp();
}

sub floss() {
  $title =~ s/Weekly //i;
  $title =~ s/:/ -/;

  write_tag("FLOSS Weekly");
  rename($filename, "$title.mp3");
  finishUp();
}

sub jaynjack() {
  if ($title =~ /Lost Podcast \(MP3\)/i) {
    $title =~ s/Lost Podcast \(MP3\):/Jay \& Jack/i;    
  }
  
  elsif ($title =~ /Vidcast/i) {
    $title =~ s/Lost/Jay \& Jack/i;
    rename($filename, "$title.mov");
    exit();
  }
  
  $title =~ s/://;
  #$title =~ s/\"/- /;  
  $title =~ s/\"//g;
  $title =~ s/(\d\.\d\d)\ (.*)/\1 - \2/;
  
  write_tag("Jay & Jack");
  rename($filename, "$title.mp3");
  finishUp();
}

sub lugRadio() {
  $episode = $filename;
  $episode =~ s/.*s0(.)e(..).*/LugRadio [\1x\2]/i;
  $title = $episode . " " . $title;

  write_tag("LugRadio");
  rename($filename, "$title.mp3");
  finishUp();
}

sub ocdiscourse() {
  m4a2mp3();
  $filename =~ s/m4a/mp3/;

  $number = $filename;
  $number =~ s/.*(.)\.mp3/\1/;
  
  $title =~ s/.*: (.*)/\1/;
  
  if ($number < 10) {
    $number = 0 . $number;
  }
  
  if ($filename =~ /OCDEpisode/i) {
    $title = "OCD " . $number . " - " . $title;
  }
  
  elsif ($filename =~ /Offseason/i) {
    $title = "OCD Offseason " . $number . " - " . $title;
  }  

  write_tag("OC Discourse");  
  rename ($filename, "$title.mp3");
  finishUp();
}

sub officialLostPodcast() {
  $title = $filename;
  $title =~ s/Lostpodcast_(\d{4})(\d{2})(\d{2}).*/Offical Lost - \1\.\2\.\3/i;
  #$title =~ s/.*\:\ (...)\.\ (.{4}).*/Official Lost - \1 \2/;
  #print "Title:".$title."\n";
  write_tag("Official Lost");
  rename ($filename, "$title.mp3");
  finishUp();
}

sub securityNow() {
  $number = $filename;
  $number =~ s/SN-(.*)\.mp3/\1/i;
  $number = ($number / 4) - 4;

  $title =~ s/ - Sponsored by Astaro Corp\.//i;
  $title =~ s/:/ -/;
  $title =~ s/Security Now/SN/i;
  $title =~ s/\!//;
  
  if($title =~ $number) {
    $title =~ s/Your Questions, Steve\'s Answers/Q\&A/i;
  }

  write_tag("Security Now");
  rename ($filename, "$title.mp3");
  finishUp();
}

sub twit() {
  $title =~ s/:/ -/;

  write_tag("TWiT");
  rename ($filename, "$title.mp3");
  finishUp();
}

sub windowsWeekly() {
  $title =~ s/:/ -/;
  
  write_tag("Windows Weekly");
  rename ($filename, "$title.mp3");
  finishUp();
}

######## Helper Methods ########

sub notify() {
  $message = $_[0];
  #$message =~ s/\'//;
  `zenity --info --text "$message" &`
}

sub write_tag() {
  $tag = $_[0];
  $command = sprintf ("id3v2 -D '%s' && id3v2 --artist '%s' --album '%s' --song '%s' --TCON Podcast '%s'", $filename, $tag, $tag, $title, $filename);
  `$command`;
}

sub m4a2mp3() {
  $command = "/home/dave/.bin/m4a2mp3 " . $filename;
  `$command`;
}

sub finishUp() {
  &notify("$title tagged and renamed successfully");
  $lnkOld = join('/', $slash,$D,$mnt,$podcast,$podcastName,$title);
  $lnkNew = join('/',$slash,$D,$mnt,$podcast,New,$title);
  symlink($lnkOld.".mp3", $lnkNew.".mp3");
}
