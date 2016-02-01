#! /usr/bin/perl 

#地点(R)
#机构名称表征词(U)
#机构类型(T)
#名称后缀(S)
#example “深圳华为技术有限公司”中，R=深圳，U=华为，T=技术，S=有限公司

use DBI;
use Time::HiRes qw(time);
use Record;
use utf8;




sub queryDB {

my $DB = 'search';
my $USER = 'wei';
my $PASSWORD = '5erendiqity';
my $number = $ARGV[0];

if (!defined $number){$number = 1000;}
#my $DISPLAY = 20;


my $DEBUG = 0;  #level of debug info, 0: no debug, 1:some info, 2:more info ... etc

$dbh=DBI->connect("DBI:Pg:dbname=$DB", $USER, $PASSWORD,{'RaiseError' => 1});
$table_name = 'name_list_new';
#$pinyin_prob_table = 'pinyin_prob';

%visited = ();

$myquery = "SELECT COUNT(*) FROM $table_name";
my $sth = $dbh->prepare($myquery);
$sth->execute();

#@db_match_array = {};
my @eva_records = ();

# iterate through resultset
# print values
@aRow = $sth->fetchrow_array;

$total_record = $aRow[0];

print "total records = $total_record\n";

while (keys %visited < $number){
  $id = int(rand($total_record));
  
  if(defined $visited{$id} ) { next;}
  else{
 	#ignore error-able records, mainly those whose U pinyin contains SZ, SZS
     $myquery = "SELECT corp_name, p_py, u_py, t_py, s_py FROM $table_name ,to_tsquery('szs| sz') queryTmp  WHERE id=$id and p_py != '' and u_py != '' and t_py != '' and s_py != '' and not queryTmp @@ u_py_idx";    
     # print "$myquery\n";          
      my $sth = $dbh->prepare($myquery);
      $sth->execute();

      @aRow = $sth->fetchrow_array;
      if(@aRow > 0){
	   $record_string =join ("|",@aRow ) ;
	  
	   $record_string =~ s/\s+/ /g;
	   #print "$record_string\n";
	   push(@eva_records,$record_string);
	   $visited{$id} = 1;
	}else{
		next;
	}	

    }
 }

  return \@eva_records;
}


sub queryFile {
  my ($f) = shift @_ ; 
  my @eva_records = ();
  open (F, "$f");
  while(<F>){
  chomp ;
  push(@eva_records,$_);
  }
  close F;

  return \@eva_records ;
}

#$qm = queryDB() ;
$qm = queryFile("evalist.txt");

@eva_records = @$qm ;
@eva = ();
$num = @eva_records;

$t0 = time;
foreach $rc (@eva_records){
	#print "->$rc \n";
	my ($name, $r, $u, $t, $s) = split(/\|/,$rc);
	#print "$name $r $u $t $s \n";
 
	@array_r = split(/\s+/,$r);
	@array_u = split(/\s+/,$u);
	@array_t = split(/\s+/,$t);
	@array_s = split(/\s+/,$s);
       # print "$name\t$array_r[0] $array_u[0] $array_t[0] $array_s[0]\n";
	my $cmd = "./iSearch.pl '$array_r[0] $array_u[0]' ";
	
        $t1 = time;	
	@result = qx ($cmd);
        $t = (time - $t1);
        print "cmd: $cmd\n";
	#print "search string = $array_r[0] $array_u[0] $array_t[0] in $t seconds.\n";

	for($i=0;$i<@result;$i++){
	   if($result[$i] =~ /$name/){
		print "found at $i\n";
		$eva[$i]++;
		last;
 	   }
        }
       # print "$name -> $result[0]\n";
       #print "$name -> $result[1]\n";
}
 $t2 = time;
 $t = ($t2 - $t0);
 print "$num records tested in $t seconds.\n";
 $top1 = $eva[0];
 $top2 = $eva[1] + $top1;
 $top3 = $eva[2] + $top2;
 $top4 = $eva[3] + $top3;
 $top5 = $eva[4] + $top4;
 $top10 = $top5 + $eva[5] + $eva[6] + $eva[7]+ $eva[8]+ $eva[9];
 
 $p1 = $top1 / $num *100;
 $p2 = $top2 / $num *100;
 $p3 = $top3 / $num *100;
 $p4 = $top4 / $num *100;
 $p5 = $top5 / $num *100;
 $p10 = $top10 / $num*100;  
 print "top1 = $top1 ($p1\%)\n";
 print "top2 = $top2 ($p2\%)\n";
 print "top3 = $top3 ($p3\%)\n";
 print "top4 = $top4 ($p4\%)\n";
 print "top5 = $top5 ($p5\%)\n";
 print "top10 = $top10 ($p10\%)\n";


# foreach $count (@eva) {
#   print "$j -> $eva{$j}\n";
      
# }
 

