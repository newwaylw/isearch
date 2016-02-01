#! /usr/bin/perl -w
#地点(R)
#机构名称表征词(U)
#机构类型(T)
#名称后缀(S)
#example “深圳华为技术有限公司”中，R=深圳，U=华为，T=技术，S=有限公司

use DBI;
use Time::HiRes qw(time);
use Record;
use Encode qw/encode decode/;
use Algorithm::LCSS qw( LCSS CSS CSS_Sorted );

my $host = 'localhost'; #'211.162.69.239';
my $port = 5432 ;
my $DB = 'search';
my $USER = 'wei';
my $PASSWORD = '5erendiqity';
my $LIMIT = 1000;
my $DISPLAY = 20;
my $gbk_encode = 0; # 1 for gbk encode output, other for UTF8;

my $WEIGHT_U = 3;
my $WEIGHT_R = 1;
my $WEIGHT_S = 1;
my $WEIGHT_T = 1;

my $DEBUG = 0;  #level of debug info, 0: no debug, 1:some info, 2:more info ... etc
my $DSN = "DBI:Pg:dbname=$DB;host=$host";
#$dbh=DBI->connect("DBI:Pg:dbname=$DB; host="$host", $USER, $PASSWORD,{'RaiseError' => 1});
$dbh=DBI->connect($DSN, $USER, $PASSWORD,{'RaiseError' => 1});
$table_name = 'name_list_new';
#$pinyin_prob_table = 'pinyin_prob';

if(@ARGV == 0){
 print "please give some keyword for me to search\n";
 exit(0);
}
$keyword=$ARGV[0];

if(length ($keyword) < 2){
	print "please input at least 2 chararacters.\n";
	exit(0);
}
#$cstr = "";
$qq = ngram($keyword,2,'|'); #create bigram list here
$ts_keyword = $keyword;
$ts_keyword =~ s/\s+/|/g;

#watch out of what you want from DB;

#$sql="select id, corp_name, name_letter, u_py, t_py, s_py, p_py, u_name, t_name, s_name, p_name   FROM $table_name ,to_tsquery('$keyword') query ,to_tsquery('$qq') query2 WHERE query2 @@ name_letter_idx $cstr ORDER BY (ts_rank(u_py_idx, query)*5+ts_rank(t_py_idx, query)+ts_rank(s_py_idx, query)+ts_rank(p_py_idx, query)+ts_rank(name_letter_idx, query2)*5 )  DESC limit 1000 ";

#$sql="SELECT id, corp_name FROM $table_name  WHERE  name_letter_idx @@ to_tsquery('$qq') ";

#recall records that contains ANY U part (keyword part) bigram PinYin matches 
#$sql="SELECT corp_name, name_letter, u_py, t_py, s_py, p_py, full_name_letter FROM $table_name  WHERE  u_py_bi_idx @@ to_tsquery('$qq') LIMIT $LIMIT";

##orignial 
#$sql="select corp_name, name_letter, u_py, t_py, s_py, p_py, full_name_letter FROM $table_name ,to_tsquery('$ts_keyword') query ,to_tsquery('$qq') query2 WHERE query2 @@ name_letter_idx $cstr ORDER BY (ts_rank(u_py_idx, query)*5+ts_rank(t_py_idx, query)+ts_rank(s_py_idx, query)+ts_rank(p_py_idx, query)+ts_rank(name_letter_idx, query2)*5 )  DESC limit $LIMIT ";

#'sz szs' cannot appear in U type! - too many errors in the db.
$sql="select corp_name, name_letter, u_py, t_py, s_py, p_py, full_name_letter FROM $table_name ,to_tsquery('$ts_keyword') query ,to_tsquery('$qq') query2 ,to_tsquery('szs| sz') queryTmp WHERE query2 @@ name_letter_idx and not queryTmp @@ u_py_idx   ORDER BY (ts_rank(u_py_idx, query)*5+ts_rank(t_py_idx, query)+ts_rank(s_py_idx, query)+ts_rank(p_py_idx, query)+ts_rank(name_letter_idx, query2)*5 )  DESC limit $LIMIT ";

#$sql="SELECT corp_name, name_letter, u_py, t_py, s_py, p_py, full_name_letter FROM $table_name  WHERE  id=141452  or  id=154187 "; 
#print "QUERY=$sql\n";

$t1 = time ;
# execute SELECT query
my $sth = $dbh->prepare($sql);
$sth->execute();
$t2 = time - $t1;

@db_match_array = {};
$no_row = 0;


# iterate through resultset
# print values
while(@aRow = $sth->fetchrow_array){
	$aRow[0] =~ s/\s+$//;
	$aRow[1] =~ s/\s+$//;
	$aRow[2] =~ s/\s+$//;
	$aRow[3] =~ s/\s+$//;
	$aRow[4] =~ s/\s+$//;
	$aRow[5] =~ s/\s+$//;
	$aRow[6] =~ s/\s+$//;
#  print "[$aRow[1],$aRow[2]]\n";
	if($aRow[2] eq 'szs sz') { next;} # some errors in the db.
	
my @str_u = sort { length($b)<=> length($a) } split(/\s+/,$aRow[2] ); #may contain multiple pinyin, sort by length.
my @str_t = sort { length($b)<=> length($a) } split(/\s+/,$aRow[3] );
my @str_s = sort { length($b)<=> length($a) } split(/\s+/,$aRow[4] );
my @str_r = sort { length($b)<=> length($a) } split(/\s+/,$aRow[5] );




 $aRecord = new Record($aRow[0],$aRow[1],\@str_u,
				\@str_t,\@str_s,\@str_r, $aRow[6]);

	$db_match_array[$no_row++] = $aRecord;
}

if($DEBUG>0){print " $no_row matched, in $t2 seconds\n";}
# clean up
$dbh->disconnect();

$t1 = time ;
foreach $r (@db_match_array){
    #we need to distinguish RUTS types.
#    print "r=[$r]\n";
    my $py = $r->getPinYinInitials();
#    my $base_score = base_scoring($keyword, $r );
#	$r->setScore($base_score);	
    my $ruts_score = score($keyword, $r );
    $r->setScore($ruts_score);	
#    $hash{$r} = $score;
}
$t2 = time ;

$t3 = $t2 - $t1;
if($DEBUG>0){print " $no_row record scored in $t3 seconds \n";}
#display ranked 
@ordered = sort { $b->getScore() <=> $a->getScore() } @db_match_array;

$t3 = time - $t2;

if($DEBUG>0) {print " $no_row record sorted in $t3 seconds \n";}
#my @records = keys %hash ;
#print "::$records[0]\n";
my $c = 0;
my $no = @ordered;
#check $DISPLAY value.
if($DISPLAY <= 0 || $DISPLAY> $no){
     $DISPLAY = $no;
}
foreach my $r (@ordered[0..$DISPLAY-1] ){
	$c++;
	my $name = $r->getName();
	my $score = $r->getScore();
        if($gbk_encode ==1){
        $name = decode("utf8", $name);
    	$name = encode("euc-cn",$name);
    	
        }
	print "$c\t$name\t$score\n";
}

sub getProb {
   my $py = $_[0] ;
   my @probs = (0,1,0,0);
   my $sql = 'SELECT count_r, count_u, count_s, count_t FROM 
	 	$pinyin_prob_table WHERE pinyin=$py';
   my $sth = $dbh->prepare($sql);
   $sth->execute();
   
   @aRow = $sth->fetchrow_array;
   if(@aRow == 1){
     my $total = $aRow[0]+$aRow[1]+$aRow[2]+$aRow[3];
     $probs[0] = $aRow[0]/$total; 
     $probs[1] = $aRow[1]/$total;
     $probs[2] = $aRow[2]/$total;
     $probs[3] = $aRow[3]/$total;
   }
   #return the RUTS probabilities of this pinyin.   
   return @probs ;
}


#given a py sequence and a record, find out the best
#RUTS parts for this py sequence. 
#bestSegmentation(str, record)
sub bestSegmentation {
my ($input,$record) = @_;
my $index = 0;
my $r ='';
my $u ='';
my $s ='';
my $t ='';
$input = lc ($input);

my $str_r_ref = $record->getRPinyin(); #may contain multiple pinyin, sort by length.
my $str_u_ref = $record->getUPinyin();
my $str_t_ref = $record->getTPinyin();
my $str_s_ref = $record->getSPinyin();

@str_r =@$str_r_ref;
@str_s =@$str_s_ref;
@str_u =@$str_u_ref;
@str_t =@$str_t_ref;

my $idx = -1;

#if there are no match or u type string here, it doesn't mean there is no U string in the input
# it just mean there are no EXACT match of it compared it with DB store.

foreach my $str (@str_u){
 $idx = index($input,$str);
 #found a match!
# print "input=[$input],trying to match with [$str], found index=$idx\n";
 if ($idx >= 0){ $u = $str; $input=~s/$str/U/; last;} # tag U in input where it is type U

}

foreach my $str (@str_s){
 $idx = index($input,$str);
 #found a match!
# print "input=[$input],trying to match with [$str], found index=$idx\n";
 if ($idx >= 0){ $s = $str; $input=~s/$str/S/; last;} # tag S in input where it is type S
  else{
    $s='';
  }
}

foreach my $str (@str_r){
 $idx = index($input,$str);
 #assume R only appears on the firstpart found a match!
 if ($idx == 0){ $r = $str; $input=~s/$str/R/; last;}# tag R in input where it is type R
    else{
    $r='';
  } 
}

foreach my $str (@str_t){
 $idx = index($input,$str);
 #found a match!
  if ($idx >= 0){ $t = $str; $input=~s/$str/T/; last;}# tag T in input where it is type T
     else{
      $t='';
     }

}

#print "$input\n";
#get rid of left over SRT part, e.g.  前进店 qjd, but we only matched R = qj,  d should be ignored
#$input=~s/S[a-z]+//;
#$input=~s/R[a-z]+//;
#$input=~s/T[a-z]+//;

$input =~s/S//;
$input =~s/R//;
$input =~s/T//;


#consider leftovers are U if not U matched earlier.
if($u eq ''){
$u = $input;
}
if($DEBUG>1){print "proposed segmentation: R=[$r], U=[$u], T=[$t], S=[$s] \n";}
my @ruts_output=($r, $u, $t, $s);
return \@ruts_output;
}


sub score {
my ($query, $record) = @_;
my @ruts =('','','','');
my $score ;
@q = split(/\s+/,$query);

if(scalar(@q) == 1){
 #maybe it is the exact pinyin sequence
 if ($q[0] eq $record->getPinYinInitials()){
	$score = exp(length ($q[0]))**2;
 }else{
 #a single string, it must be U
 $ruts[1] = $q[0];
 $score = ruts_scoring(\@ruts, $record);
 }
}elsif(scalar(@q) ==2){
 # if input contains two parts, it is R+U or U+R or U+T or U+S score both and select the max.
  #consider it is R+U;
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[0],$q[1],'','');
  my $score1 = ruts_scoring(\@ruts, $record)+0.1; #break tie, prefer R+U if tie.
  #or a U+R
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[1],$q[0],'','');
  my $score2 = ruts_scoring(\@ruts, $record) +0.09;
  #or a U+T
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ('',$q[0],$q[1],'');
  my $score3 = ruts_scoring(\@ruts, $record)+0.08;
  #or a U+S
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ('',$q[0],'',$q[1]);
  my $score4 = ruts_scoring(\@ruts, $record)+0.07;

  #or NO U! 
  # RT
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[0],'',$q[1],'');
  #my $score4 = ruts_scoring(\@ruts, $record)+0.07;

  $score = max($score1, $score2,$score3);

 }elsif(scalar(@q) == 3 ){
  #has tree parts, can be RUT, RUS, URT, URS, TUR, SUT	
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[0],$q[1],$q[2],''); #RUT
   my $score1 = ruts_scoring(\@ruts, $record)+0.1; 
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[0],$q[1],'',$q[2]); #RUS
   my $score2 = ruts_scoring(\@ruts, $record)+0.09; 
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[1],$q[0],$q[2],''); #URT
   my $score3 = ruts_scoring(\@ruts, $record)+0.08;
  ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[1],$q[0],'',$q[2]); #URS
   my $score4 = ruts_scoring(\@ruts, $record)+0.07;
   $score = max($score1,$score2,$score3,$score4);
  }elsif(scalar(@q)==4){
    #RUTS, URTS
    @ruts = @q; # RUTS
    my $score1 = ruts_scoring(\@ruts, $record)+0.1;
    ($ruts[0],$ruts[1], $ruts[2], $ruts[3]) = ($q[1],$q[0],$q[2],$q[3]); #URTS
    my $score2 = ruts_scoring(\@ruts, $record)+0.09; 
    $score = max($score1, $score2);
  }

return $score ;
}



######################score the relevance between an @ruts segmentation and a record : LCSS based.############
sub ruts_scoring {
my ($q,$record) = @_ ;
my $ruts_match_no = 0; # matched U, RU, RUT, RUTS ?深圳市宝德利服装有限公司
my $matched_r_char = 0;
my $matched_u_char = 0;
my $matched_t_char = 0;
my $matched_s_char = 0;
my @ruts = @$q;

#if($DEBUG>0){print"RUTS=$ruts[0],$ruts[1],$ruts[2],$ruts[3]\n";}
my $score = 0;
my $record_py = $record->getPinYinInitials();

my @tmp_r = @{$record->getRPinyin()};
my @tmp_u = @{$record->getUPinyin()};
my @tmp_t = @{$record->getTPinyin()};
my @tmp_s = @{$record->getSPinyin()};

if($DEBUG > 0){print "scoring($ruts[0],$ruts[1],$ruts[2],$ruts[3])with ($tmp_r[0],$tmp_u[0],$tmp_t[0],$tmp_s[0]) : $record\n";}


#score R type
if(defined $ruts[0] && length ($ruts[0]) > 0){
my $max = 0;
my $idx = 0;
#print "R=$ruts[0]\n";
my $r_py = $record->getRPinyin();
foreach $r (@$r_py){
 my $score_tmp = 0;
 my $r_len = length($r);
 #if two shares no common substring...?
 my $r_lcss = LCSS($ruts[0],$r);
 if($DEBUG>1){ print "LCSS [$ruts[0]] and [$r] = $r_lcss\n";}
 if(defined $r_lcss && length ($r_lcss) > 0){
  #exact match, give high score
  $len = length ($r_lcss);
      if($ruts[0] eq $r){
	

	 $matched_r_char = $len ;
         $max = exp($len)*2;
	 if($DEBUG>1){print "Exact match on R, give score $max\n";}     
	 last; 
      }   
    #partial match
   $ruts_match_no++;
   $matched_r_char = max($matched_r_char,length ($r_lcss));
   $idx = index($r, $r_lcss);
   $score_tmp = (exp(1)- ($idx/$len))**($len); # (e- idx/lcss) ^$len prefer fronter matches.
#   print"un-normalized score = $score_tmp\n";
   my $diff = abs(length($r) - length($r_lcss));
   if($diff > 0){
     $score_tmp /= ($diff+1); #normalize length effect.
  if($DEBUG>1){print"normalized score = $score_tmp\n";}
   }
   
   #for multiple R-pinyins, find the one with the max score and use that.
   $max = max($max,$score_tmp);
   $idx++;
 }#end of if

}
 if($DEBUG>1){print "selected R score = $max\n";}
 $score += ($max*$WEIGHT_R);
}
################################################################

########################!!! score U type !!!############################

if(length ($ruts[1]) > 0){
my $max = 0;
#print "U=$ruts[1]\n";
my $u_py = $record->getUPinyin();
foreach $u (@$u_py){
 my $score_tmp = 0;
 my $len = 0;
 my $idx = 0; # where the CSS begins.
 #my $u_len = length($u);
 my $u_lcss = LCSS($ruts[1],$u);
 if($DEBUG > 1){print "LCSS [$ruts[1]] and [$u] = $u_lcss\n";}
   if(defined $u_lcss && length ($u_lcss) > 0){
      $len = length ($u_lcss);            
      #exact match on only u type, give high score
      if($ruts[1] eq $u){
 	if($u_py == 1){
         $max = exp($len)**2;
	 #exact match but db has other u pinyin for this entry as well
	 }else{
	  $max = exp($len)**sqrt(2);
  	  }
          $matched_u_char = $len ;
	  if($DEBUG>1){print "Exact match on U, give score $max\n";}     
	  last; 
      }   
      #partial match
      $matched_u_char = max($matched_u_char,$len);
      $idx = index($u, $u_lcss);
      $score_tmp = (exp(1)- ($idx/$len))**($len); # (e- idx/lcss) ^$len prefer fronter matches.
      my $diff = abs(length($u) - $len);
      if($diff > 0){
         $score_tmp /= ($diff+1); #normalize length effect.
         if($DEBUG > 1){print"normalized U score = $score_tmp\n";}
      }
   
    #for multiple R-pinyins, find the one with the max score and use that.
    if($DEBUG>1){print "max ($max, $score_tmp)=";}
    $max = max($max,$score_tmp);
    if($DEBUG>1){print "$max\n";}
    $idx++;
  }#end of if
   if($DEBUG>0){print "match $ruts[1] and $u = $len \n";}
 }#foreach
 
 $score += ($max*$WEIGHT_U);
 if($DEBUG > 0){print"matched char = [$matched_u_char]";print "selected U score = [$score]\n";}
}
################################################################


##########################score T type##########################
#$idx = 0;

if(defined $ruts[2] && length ($ruts[2]) > 0){
my $max = 0;
#print "T=$ruts[2]\n";
my $t_py = $record->getTPinyin();
foreach $t (@$t_py){
 my $score_tmp = 0;
# print "finding LCSS [$ruts[2]] and [$t] \n";
 my $t_lcss = LCSS($ruts[2],$t);
 if(defined $t_lcss && length ($t_lcss) > 0){
   $ruts_match_no++;
   $score_tmp +=exp(length ($t_lcss));
   $matched_t_char = max($matched_t_char,length ($t_lcss));
   my $diff = abs(length($t) - length($t_lcss));
   if($diff > 0){
     $score_tmp /= ($diff+1); #normalize length effect.
     if($DEBUG > 1){print"normalized T score = $score_tmp\n";}
   }
   
   #for multiple R-pinyins, find the one with the max score and use that.
   $max = max($max,$score_tmp);
   $idx++;
 }#end of if
}
 $score +=($max * $WEIGHT_T);
 if($DEBUG > 0){print "selected T score = $score\n";}

}

###############################score S type############################

if(defined $ruts[3] && length ($ruts[3]) > 0){
my $max = 0;
#print "S=$ruts[3]\n";
my $s_py = $record->getSPinyin();

foreach $s (@$s_py){
 my $score_tmp = 0;
if($DEBUG>1){ print "finding LCSS [$ruts[3]] and [$s] \n";}
 my $s_lcss = LCSS($ruts[3],$s);
 if(defined $s_lcss && length ($s_lcss) > 0){
   $ruts_match_no++;
   $score_tmp +=exp(length ($s_lcss));
   $matched_s_char = max($matched_s_char,length ($s_lcss));
   my $diff = abs(length($s) - length($s_lcss));
   if($diff > 0){
     $score_tmp /= ($diff+1); #normalize length effect.
     if($DEBUG > 1){print"normalized S score = $score_tmp\n";}
   }
   
   #for multiple R-pinyins, find the one with the max score and use that.
   $max = max($max,$score_tmp);
   $idx++;
 }#end of if
}#foreach
 $score +=($max * $WEIGHT_S);
 if($DEBUG > 0){print "selected S score = $score\n";}
}
#########################################################################

#take into account the length of input query and the record,
#this is to avoid some record that are very long so can score higher
#for longer U types
my $matched = $matched_r_char+$matched_u_char+$matched_t_char+$matched_s_char;
#my $diff = length($record_py);
if($DEBUG>0){print "total matched char = $matched of [$record_py]\n";}

my $py_length = length($record_py);
#simple linear discount to prefer shorter strings when tie.
#BUG!!! 8 records in the db contain NO pinyin!!!
if($py_length ==0){$score = -1;} # negative score to give an indication of error on db records.
else{
   # how to discount longer terms?   
   #$score *= ($matched / $py_length);
   $score *= 1 - ($py_length - $matched)/100; 
   if($DEBUG > 0) {print "length normalized score=$score; matched=$matched, total=$py_length\n";}
 }
 # add extra score for items has more RUTS matchings
 #useful to break a tie
#$score+=$ruts_match_no;
return $score;
}


#build ngram string , separated by $sp
sub ngram {
	my ($str, $n, $sp) =  @_ ;
	if (!defined $n){ $n = 2;}
	if (!defined $sp){$sp = ' ';}
	#print "input: $str, n=$n, separator=$sp \n";
	my $ngram;
	for($i=0;$i<=length($str)-$n;$i++){
		if($i>0){$ngram.=$sp;}
		$ngram .= substr($str,$i,$n);
	}
	return $ngram;
}

#calcuate levenshtein edit distance.
sub levenshtein
{
    # $s1 and $s2 are the two strings
    # $len1 and $len2 are their respective lengths
    #
    my ($s1, $s2) = @_;
    my ($len1, $len2) = (length $s1, length $s2);

    # If one of the strings is empty, the distance is the length
    # of the other string
    #
    return $len2 if ($len1 == 0);
    return $len1 if ($len2 == 0);

    my %mat;
    for (my $i = 0; $i <= $len1; ++$i)
    {
        for (my $j = 0; $j <= $len2; ++$j)
        {
            $mat{$i}{$j} = 0;
            $mat{0}{$j} = $j;
        }

        $mat{$i}{0} = $i;
    }


    my @ar1 = split(//, $s1);
    my @ar2 = split(//, $s2);

    for (my $i = 1; $i <= $len1; ++$i)
    {
        for (my $j = 1; $j <= $len2; ++$j)
        {

            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;


            $mat{$i}{$j} = min([$mat{$i-1}{$j} + 1,
                                $mat{$i}{$j-1} + 1,
                                $mat{$i-1}{$j-1} + $cost]);
        }
    }


    return $mat{$len1}{$len2};
}


#
sub min
{
    my @list = @{$_[0]};
    my $min = $list[0];

    foreach my $i (@list)
    {
        $min = $i if ($i < $min);
    }

    return $min;
}

sub max
{
    my @list = @_;
    my $max = $list[0];

    foreach my $i (@list)
    {
        $max = $i if ($i > $max);
    }

    return $max;
}


###############score the relevance between input py string and a record : CSS based.####################
sub base_scoring{
	my $base_score = 0;  #score based on sum of CSS score
	#my $ruts_score = 0;  #score based on RUTS segmentation
	my $weight = 0;
	my ($keyword,$record) = @_ ;
	
	my $record_py = $record->getPinYinInitials();
	my $ref = CSS_Sorted($keyword,$record_py);
	#find common substrings
	my @commonSubStrings = @$ref ;
	
	foreach $cs (@commonSubStrings){
	   #accumulate score SIGMA e^(length)
	   #print "CSS: [$cs] \n";
	   my $len = length ($cs);
	   #only consider common substrings of 2 or more.
	   if($len >=2){
	      $base_score+=exp(length ($cs) );
	    }
	}
	
	#
	if( length($keyword) <= length($record_py) ){
	#normalize by the difference of the length of two strings
	#to favor shorter names
	$base_score *= (length($keyword) / length($record_py));
	}else{
	#if the actual name contains less characters than the query pinyin
	# we need to penaltize it. 
	  my $dif = length($keyword) - length($record_py);
	  $base_score /=$dif;
	}
	
	return $base_score ;
}
###########################################################################################################


########################## NOT IN USE ################################
#segment a pinyin input into RUTS form
#return the most likely segmentation in the RUTS form 
#in an array.
sub segmentation {
  my $p_threshold = 0.7;
  my @ruts = split(/\s+/,$_[0]);
  my @ruts_output = ('','','','');
  #input has manual segmentation, but R maybe at the end
  #if manual segment is 2, that can be only R+U or U+R
  if (@ruts ==2){
    my @prob1 = getProb($ruts[0]);
    my @prob2 = getProb($ruts[1]);
    #if the first pinyin seg. is more likely to be a R type
    
    #if the second pinyin is more likely to be a R type
    if ($prob2[0] >= $p_threshold){
       $ruts_output[0] = $ruts[1];
       $ruts_output[1] = $ruts[0];
    }elsif($prob1[0] >= $prob2[0]){
       $ruts_output[0] = $ruts[0];
       $ruts_output[1] = $ruts[1];
     }
  }#if
  
  # input has manual segment 3, must be RUT or RUS,
  if(@ruts ==3){

    $ruts_output[1] = $ruts[1];
   
    my @prob1 = getProb($ruts[0]);
    my @prob2 = getProb($ruts[2]);
    #if the first pinyin seg. is more likely to be a R type
    if ($prob1[0] >= $prob2[0]){
       $ruts_output[0] = $ruts[0];
       $ruts_output[2] = $ruts[2];
    #if the third pinyin is more likely to be a R type
    }elsif ($prob2[0] >= $p_threshold){
       $ruts_output[0] = $ruts[2];
       $ruts_output[2] = $ruts[0];
    }
  }

  if(@ruts == 4){
    #location of U is always 2nd.
    $ruts_output[1] = $ruts[1];
    $ruts_output[2] = $ruts[2];
    $ruts_output[3] = $ruts[3];
	
    my @prob1 = getProb($ruts[0]);
    my @prob2 = getProb($ruts[3]);

    if ($prob1[0] >= $prob2[0]){
       $ruts_output[0] = $ruts[0];
       $ruts_output[4] = $ruts[4];
    #if the fourth pinyin is more likely to be a R type
    }elsif ($prob2[0] >= $p_threshold){
       $ruts_output[0] = $ruts[4];
       $ruts_output[4] = $ruts[0];
    }
  }

   #input contains on segmentation, we need to propose one
   if(@ruts==1){
    #assume R T S contains 2 - 4 characters
    my $i=4;
    my $str = $ruts[0];
    while($i >= 2){
      my $candidate_r = substr($str,0,$i);
      my $prob_r = ${getProb($candidate_r)}[0];
      if($prob_r > $p_threshold){
	$ruts_output[0] = $candidate_r;
	last;
      }else{
	$i--;
       }
    }#while

    $str = substr($str, $i, length($str) );
		

   }

   return @ruts_output ;
}
##################################NOT IN USE###################################


