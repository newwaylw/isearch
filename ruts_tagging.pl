#! /usr/bin/perl -w

#use utf8;
binmode(STDOUT, ":utf8");
open(F, "<:utf8","type.hash");
while(<F>){
s/\s+$//;
s/^\s+//;
($w,$freq) = split(/\t/, $_);
$len = length ($w);
#print ":len of $w = $len\n";
$hash_t{$w} = $freq;
}
close F;

open(F, "<:utf8","suffix.hash");
while(<F>){
s/\s+$//;
s/^\s+//;
($w,$freq) = split(/\t/, $_);
$hash_s{$w} = $freq;
}
close F;

#open(F,"<:utf8", "area.txt");
open(F, "<:utf8","area.txt");
while (<F>){
s/\s+$//;
s/^\s+//;

$name = $_;
$len = length($name);
#print "len of $_ = $len \n";
if($len >=3){
 $short = substr($name,0,$len-1);
# print "$short\n";
 $hash_r{$short}++;
}
$hash_r{$name} ++;
}
close F;

#exit(0);
open(F, "<:utf8","$ARGV[0]");
while(<F>){
  chomp ;
  s/有限\s+公司/有限公司/g;
  @words = split(/\s+/,$_);
  foreach $word (@words){
     $tag ='';
     # a possible r type 
     if(defined $hash_r{$word}){
         $tag = "r"; 
     }elsif(defined $hash_t{$word}){
          $tag = "t";
      }elsif(defined $hash_s{$word}){
           $tag = "s";
	}else{
	   
	}
	print "$word". '/' ."$tag ";
  }
	print "\n";
}
close F;
