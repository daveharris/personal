#!/usr/bin/perl

$fullPath = $ARGV[0];
$title = $ARGV[1];

$filepath = $fullPath;
$filepath =~ s/^(.*)\/.*$/$1/;
$filename = $fullPath;
$filename =~ s/^.*\/(.*)$/$1/;
$podcastDir = $fullPath;
$podcastDir =~ s/^(.*)\/.*\/.*$/$1/;
$podcastName = $fullPath;
$podcastName =~ s/.*\/(.*)\/.*$/$1/;

if($fullPath =~ /Security/) {
  securityNow();
}
elsif($fullPath =~ /\.mp3/) {
  writeTag();
  symlink($fullPath, $podcastDir."/New/".$filename);
  notify();
}
else {
  symlink($fullPath, $podcastDir."/New/".$filename);
  notify();
}

sub securityNow() {  
  $number = $filename;
  $number =~ s/SN-(.*)\.mp3/$1/i;
  $number = ($number / 4) - 4;

  $title =~ s/\`/\'/g;
  $title =~ s/ - Sponsored by Astaro Corp\.?//i;
  $title =~ s/:/ -/;
  $title =~ s/Security Now/SN/i;
  $title =~ s/\!//;
  
  if($title =~ $number) {
    $title =~ s/Your Questions, Steve\'s Answers/Q\&A/i;
  }

  writeTag();
  chdir($podcastDir.'/Security Now!');
  rename ($filename, "$title.mp3");
  $fullPath = $podcastDir.'/Security Now!'."/$title.mp3";
  symlink($fullPath, $podcastDir."/New/".$title.".mp3");
  notify();
}

######## Helper Methods ########

sub notify() {
  $message = "$filename tagged and renamed successfully";
  `zenity --info --text "$message" &`;
}

sub writeTag() {
  $command = sprintf("id3v2 -D '%s' && id3v2 --artist '%s' --album '%s' --song '%s' --TCON Podcast '%s'", $fullPath, $podcastName, $podcastName, $title, $fullPath);
  `$command`;
}
