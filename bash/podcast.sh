#Written by David Harris (david.harris <at> orcon.net.nz)

#Takes in the fullpath of the podcastz and tags/renames file
#Pops up when finished

#!/bin/bash

filename="$(echo $1 | cut -d '/' -f 6)"
#echo "Filename: $filename"
dir="$(echo "$1" | sed 's/\(.*\)\/.*/\1/')"
#echo "Dir: $dir"

notify () {
  zenity --info --text "$1 was downloaded and tagged successfully" &
}

testTitle () {
  if [ -z "$title" ]; then 
    echo "The Title is empty ... quitting"
    exit
  fi
}

diggnation () {
  title="Diggnation $(echo "$filename" | cut -d '-' -f 3 | sed 's/00\(..\)/\1/')"
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'Diggnation' --album 'Diggnation' --song "$title" --TCON 'Podcast' "$filename"  
  mv "$filename" "$title.mp3"
  notify "$title"
}

floss () {
  title=$(id3v2 -l "$filename" | grep TIT2 | cut -d ' ' -f 4- | sed 's/:/ -/')
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'FLOSS' --album 'FLOSS' --song "$title" --TCON 'Podcast' "$filename"
  mv "$filename" "$title.mp3"
  notify "$title"
}

jaynjack () {
  #title=$(id3v2 -l "$filename" | grep Title | cut -d ' ' -f 8)
  #if [ "$title" = "1-X" ]; then
  #title=$(id3v2 -l "$filename" | grep TIT2 | cut -d ' ' -f 7- | sed 's/\"//g' | sed 's/\(Ep\. .\...\) \(.*\)/Jay \& Jack \1 - \2/')
  title=$(id3v2 -l "$filename" | grep 'Title' | cut -d ' ' -f 7- | sed 's/  Artist.*//')
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'Jay & Jack' --album 'Jay & Jack' --song "$title" --TCON 'Podcast' "$filename"
  mv "$filename" "$title.mp3"
  notify_title=$(echo $title | sed 's/&/and/')
  notify "$notify_title"
}

lost () {
  title="Lost $(echo "$filename" | cut -d '_' -f 2)"
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'Lost' --album 'Lost' --song "$title" --TCON 'Podcast' "$filename"
  mv "$filename" "$title.mp3"
  notify "$title"
}

lugradio () {
  title="LugRadio $(echo $filename | cut -d '-' -f 2 | sed 's/s0\(.\)e\(..\)/[\1x\2]/')"
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'LugRadio' --album 'LugRadio' --song "$title" --TCON 'Podcast' "$filename"
  mv "$filename" "$title.mp3"
  notify "$title"
}

novell () {
  title="Novell Open Audio $(echo $filename | cut -d '/' -f 6 | sed 's/.*_.\(..\).*/\1/')"
  testTitle
  description=$(id3v2 -l "$filename" | grep TIT2 | cut -d ' ' -f 4-)
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'Novell Open Audio' --album 'Novell Open Audio' --song "$description" --TCON 'Podcast' "$filename"
  mv "$filename" "$title.mp3"
  notify "$title"
}

twit () {
  title=$(id3v2 -l "$filename" | grep 'TIT2' | cut -d ' ' -f 4-)
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'TWiT' --album 'TWiT' --song "$title" --TCON 'Podcast' "$filename"
  title=$(echo $title | sed 's/\:/\ -/')
  mv "$filename" "$title.mp3"
  notify "$title"
}

security_now () {
  title=$(id3v2 -l "$filename" | grep 'TIT2' | cut -d ' ' -f 4- | sed 's/Security Now/SN/'| sed 's/: / - /' | cut -d '-' -f 1-2 | sed 's/ $//' )
  testTitle
  id3v2 -D "$filename" &>/dev/null
  id3v2 --artist 'Security Now!' --album 'Security Now!' --song "$title" --TCON 'Podcast' "$filename"
  mv "$filename" "$title.mp3"
  notify "$title"
}

cd "$dir"

#artist=$(id3v2 -l $filename | grep Artist | cut -d ':' -f 4 | cut -d ' ' -f 2,3)
#artist=$(id3v2 -l "$filename" | grep "Jeremiah")
#if [ -n "$artist" ]; then #= "Jeremiah Glatfelter" ]; then
#  jaynjack
#fi
 
case "$filename" in
  diggnation* ) diggnation ;;
  FLOSS* ) floss ;;
  Lostpodcast* ) lost ;;
  lugradio* ) lugradio ;;
  TWiT* ) twit ;;
  SN* ) security_now ;;
  noa* ) novell ;;
  * ) jaynjack;;
esac
