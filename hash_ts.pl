#! /usr/bin/perl -w

%hash_t = ();
%hash_s = ();
while(<>){
chomp;
@ts = split(/\|/,$_);
  
 @t = split(/\s+/,$ts[0]);
 @s = split(/\s+/,$ts[1]);

 foreach $type (@t){
   $hash_t{$type} ++;
 }

 foreach $suffix (@s){
   $hash_s{$suffix} ++;
 }
}

foreach $key (sort {$hash_s{$b} <=> $hash_s{$a}} keys %hash_s){
   print "$key\t$hash_s{$key}\n";

}


