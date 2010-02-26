# Author: Neil Rammsay
# Description: Replaces all <tabs> with 2 spaces 

#! /usr/bin/perl
while (my $file = shift(ARGV)) {
    if(!(-e $file && -f $file)) {
	die "$file is not a file or does not exist";
    }

    open(FILE, "< $file");
    
    my $contents;
    my $line;
    while(defined($line = readline(FILE))) {
	$line =~ s/  /\t/gi;
	$contents .= $line;
    }

    close(FILE);

    open(FILE, "> $file");
    print FILE $contents;
    close(FILE);
}
