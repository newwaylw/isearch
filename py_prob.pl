#! /usr/bin/perl -w

#地点(R)
#机构名称表征词(U)
#机构类型(T)
#名称后缀(S)
#example “深圳华为技术有限公司”中，R=深圳，U=华为，T=技术，S=有限公司

use DBI;
use Time::HiRes qw(time);
use Record;

my $DB = 'search';
my $USER = 'wei';
my $PASSWORD = '5erendiqity';
my $LIMIT = 2000;
$dbh=DBI->connect("DBI:Pg:dbname=$DB", $USER, $PASSWORD,{'RaiseError' => 1});
$table_name = 'name_list_new';
$table2 = 'pinyin_prob';

#recall records that contains ANY U part (keyword part) bigram PinYin matches 
$sql="SELECT u_py, t_py, s_py, p_py FROM $table_name ";

#print "QUERY=$sql\n";

# execute SELECT query
my $sth = $dbh->prepare($sql);
$sth->execute();


$no_row = 0;
# iterate through resultset
# print values
while(@aRow = $sth->fetchrow_array){
    $aRow[0] =~ s/\s+$//;
    $aRow[1] =~ s/\s+$//;
    $aRow[2] =~ s/\s+$//;
    $aRow[3] =~ s/\s+$//;

    @u_py = split(/\s+/,$aRow[0]);
    @t_py = split(/\s+/,$aRow[1]);
    @s_py = split(/\s+/,$aRow[2]);
    @r_py = split(/\s+/,$aRow[3]); #location

    foreach $u (@u_py){
    $u = lc $u;
    $u_hash{$u} ++ ;
    $total_hash{$u}++;
    }

foreach $t (@t_py){
    $t = lc $t;
    $t_hash{$t} ++ ;
    $total_hash{$t}++;
    }
foreach $s (@s_py){
    $s = lc $s;
    $s_hash{$s} ++ ;
    $total_hash{$s}++;
    }
foreach $r (@r_py){ 
    $r = lc $r ;
    $r_hash{$r} ++ ;
    $total_hash{$r}++;
    }	

}

#calculate p(Type|pinyin) : p(R|py)+p(U|py)+p(T|py)+p(S|py) = 1
#because a pinyin must be one or more of a RUTS type.


$sql="TRUNCATE TABLE $table2";
my $sth = $dbh->prepare($sql);
$sth->execute();

my $id = 0;
foreach $key (sort keys %total_hash){
    my $p_s = 0;
    my $p_r = 0;
    my $p_t = 0;
    my $p_u = 0;
    if(defined $s_hash{$key}){
    $p_s = $s_hash{$key};
    }
    if(defined $r_hash{$key}){
    $p_r = $r_hash{$key} ;
    }
    if(defined $t_hash{$key}){
    $p_t = $t_hash{$key};
    }
    
    if(defined $u_hash{$key}){
    $p_u = $u_hash{$key};
    }

    $sql="INSERT INTO $table2 (id, pinyin, count_r, count_u, count_t,count_s)
    VALUES ($id, '$key', $p_r, $p_u, $p_t, $p_s); ";

    print "EXECUTING $sql \n";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $id++ ;
    print "p(R|$key)=$p_r, p(U|$key)=$p_u, p(T|$key)=$p_t, p(S|$key)=$p_s \n";
}
 














