#! /usr/bin/perl -w
#
%hash_t = ();
%hash_s = ();
while(<>){
 s/^\s+//;
 s/\s+$//;
 @ts = split(/\t/, $_);
 $t = $ts[0];
 $s = $ts[1];

 foreach $t_word (split(/\s+/, $t) ){
    $hash_t{$t_word}++;
  }

 foreach $s_word (split(/\s+/, $s) ){
    $hash_s{$s_word}++;
  } 
}

 foreach $key (sort { $a > $b} keys %hash_t){
   print "$key\t$hash_t{$key}\n";
 }

 #foreach $key(sort { $a > $b} keys %hash_s){
 #  print "$key\t
 # }
