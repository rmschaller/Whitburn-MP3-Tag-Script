#########################################################################################################
# Author: Rob Schaller (c) 2013
#
# BACKGROUND:
#
# The motivation for writing this script maybe found by searching the Internet
# for "Whitburn Project"
#
# DESCRIPTION:
#
# This PERL script reads from a tab-delimited file, created from the Whitburn spreadsheet,
# and writes various pieces of MP3 tag information to the respective MP3 file.  This script 
# WILL NOT work if your MP3 filenames do not contain  the numbering convention YY_PPP where YY
# is the ending two digits of the year and PPP is the yearly ranking number. It is important to
# note that the delimited file should use tabs and not commas as the delimiting marker.  
# The reason is some of the fields contain commas and will mess up the parsing operation.
#
# Inputs: 
#
# User supplies the last two digits of the year, starting chart position, and ending 
# chart position.
#
# Outputs:
#
# Comment metadata in the MP3 tag for mp3 file within the range defined by start and end position.
#
# KNOWN ISSUES:
#
# This script will stop if more than one file is found with the same values for the numbering 
# convention.
# Christmas music has different numbering convention than YY_PPP as described above and will 
# not be detected. Ba humbug!
############################################################################################################
use File::Find;
use MP3::Tag;
MP3::Tag->config(write_v24 => 1);
my $fileSearchString;
my $tagSearchString;
my $validFileCnt = 0;
my $totalFileCnt = 0;
my $inputLine;
my $commentString;
# ******************* User Input Section **********************************
# User will have to customize file paths for their own computer
#
print "Make sure you are using the correct Whitburn file for the given year!!\n";
print "Specify last two digits of year,start position,end position\n";
my $argLine = <STDIN>;
chomp($argLine);
my ($year, $startPosition, $endPosition) = split(",",$argLine);
my $fileIn  = "Billboard Pop ME (1970-1979) 20101225.txt";
my $fileOut = "results.txt";
my $dir     = "/Volumes/DATABACKUP/tagProject/Whitburn".$year;
my $Prefix  = $year."_";
# do some error-checking
unless($fileIn) { die ("Missing a file name, try again!");}
#
#***************************************************************************
# ********* open the files specified by the user's arguments **********************
open(FOUT, ">".$fileOut) or die ("Error! Can't open file: $fileOut for writing!\n");
open(FIN, "<".$fileIn) or die ("Error! can't open file: $fileIn for reading!\n");
my $index;
for ($x = $startPosition ; $x < $endPosition ; $x++)
{
  if ($x < 10 )
  # This section of code pads extra zeros for numbers 1-9,10-99 so all yearly 
  # positions have three digits per the format of the database entries.
   { 
     $index      = "00".$x;
    }
   elsif(($x > 9) && ($x < 100))
    {
      $index      = "0".$x;
    } 
    elsif($x > 99)
     {
       $index      = $x;
     }
  $fileSearchString = $Prefix.$index;
  print "index is: ".$Prefix.$index."\n";
  find(\&prefixSearch, $dir);

}# end for loop
print "Total number of files found ".$totalFileCnt." ,Number of files that matched criterion is: ".$validFileCnt."\n";
close(FIN);
close(FOUT);
########################################### END OF MAIN SCRIPT, SUBROUTINES GO HERE ##########################
#
########################################### SUBROUTINE ##########################################
sub prefixSearch {
  $totalFileCnt = $totalFileCnt + 1;
  if(/$fileSearchString/)
   {
     my $foundFile = $_;# used for MP3::Tag support
     $tagSearchString = "19".$fileSearchString;
     $validFileCnt = $validFileCnt + 1; # Debug line
     while($inputLine = <FIN>)
     {
       chomp($inputLine);
       # NOTE: The tab-delimited file must have columns that follow the order below.
       my ($year,$yearlyRank,$prefix,$peak,$Artist,$album,$title,$label,$genre,$writer,$dateEntered,$datePeaked) = split("\t",$inputLine);
       $Artist = noQuotes($Artist);
       $album  = noQuotes($album);
       $title  = noQuotes($title);
       $writer = noQuotes($writer);
       if($prefix eq $tagSearchString)
       {
         print FOUT "\n";
         print FOUT "code is: ".$prefix." Peak Chart Position: ".$peak." Artist is: ".$Artist." album is: ".$album." Song is: ".$title." Record Label: ".$label." Music style: ".$genre." Written by: ".$writer." Entered the chart on: ".$dateEntered." Peaked on: ".$datePeaked."\n";
         print FOUT "------------------------------------\n";
         $commentString = "Debuted ".$dateEntered." and peaked at #".$peak." on the Hot 100 Chart".".". "Source: Pop Annual"."."." Written by ".$writer."."." Label/Number: ".$label.". Date Peaked: ".$datePeaked;
         print FOUT "$commentString";
         # Insert code that will write these values to the MP3 tags #
         ############################################################
         $mp3 = MP3::Tag->new($foundFile);
         $mp3->get_tags();
         if(exists $mp3->{ID3v2})
          {
             $mp3->{ID3v2}->title($title);
             $mp3->{ID3v2}->artist($Artist);
             $mp3->{ID3v2}->comment($commentString);
             $mp3->{ID3v2}->track($x);
             $mp3->{ID3v2}->album("Whitburn".$year);
             $mp3->{ID3v2}->write_tag();
             print "Wrote to the ID3v2 tag!\n";
           }
          elsif(exists $mp3->{ID3v1})
           {
             $mp3->{ID3v1}->title($title);
             $mp3->{ID3v1}->artist($Artist);
             $mp3->{ID3v1}->comment($commentString);
             $mp3->{ID3v1}->track($x);
             $mp3->{ID3v1}->album("Whitburn".$year);
             $mp3->{ID3v1}->write_tag();
             print "Wrote to the ID3v1 tag!\n";
           }

           $mp3->close();#destroy object
         return;
        }
       #}
      }
    }
    else
    {
      print FOUT "didn't find file: ".$fileSearchString."\n";
    }
}
 ###################### end of code for subroutine ########################
######################## SUBROUTINE ######################
# This routine strips of the quotes that appear at the beginning and end of
# the sting.  NOTE: these quotes only occur if the returned field contained
# the comma(,) mark at some point in the string.
  sub noQuotes{
	my $noQuotes = shift(@_);
   if($noQuotes =~ m/(^")/)
   {
    if($noQuotes =~ m/("$)/)
    {
      $noQuotes = substr($noQuotes,-1) = '';#remove end "
      $noQuotes = substr($noQuotes,1,length($noQuotes),'');#remove beginning "
    }
  }
  return $noQuotes;
   }
  ###################### end of code for subroutine ########################

