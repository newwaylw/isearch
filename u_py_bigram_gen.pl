#! /usr/bin/perl -w


use DBI;

#generate bigram for name pinyin
my $USER='wei';
my $PASSWORD = '5erendiqity';
my $DB = 'search';

$dbh=DBI->connect('DBI:Pg:dbname=$DB', $USER, $PASSWORD,{'RaiseError' => 1,'PrintError' => 1});
$table_name = 'name_list_new';

#$keyword=$ARGV[0];
#$cstr = "";
#$qq = ngram($keyword,2,' | '); #note the space between |, PostgreSQL to_tsquery need space between | & ...


$sql="SELECT id, u_py FROM $table_name";

# execute SELECT query
my $sth = $dbh->prepare($sql);
$sth->execute();

# iterate through resultset
# print values
while(@aRow = $sth->fetchrow_array){
	my %u_py_bi_hash = ();
	my $u_py_bigram = '';
	$u_py = $aRow[1];
	$u_py =~s/\s+$//;
	@u_py_parts = split(/\s+/,$u_py);
	foreach $part (@u_py_parts){
	$len = length($part);
	if($len <= 2) {$u_py_bi_hash{$part}++ ; } # already a 1 or 2char
	else{	
		$bi = ngram($part,2,' ') ;
		foreach $p (split(/\s+/,$bi) ){
		$u_py_bi_hash{$p}++;
		}
        }

       }
	print "$aRow[0] - [$u_py]\n";
	
	foreach $k (keys %u_py_bi_hash){
	  $u_py_bigram .= "$k".' ';
	  #print "->$k\n";
	}
	

	$sql_upd = "UPDATE $table_name SET u_py_bi_idx = to_tsvector('$u_py_bigram') WHERE id=$aRow[0];";
	print "$sql_upd\n";
	#$dbh->do('Begin');
	my $sth = $dbh->prepare($sql_upd);
	$sth->execute() or die "Can't execute SQL statement: $DBI::errstr\n";
	#$dbh->do('Commit');
}
# clean up
$dbh->disconnect();






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
