<?
define("_ROOT",".");
$table_name="name_list_all";
$p = explode("\r\n",file_get_contents("p.txt"));
$t = explode("\r\n",file_get_contents("t.txt"));
$s = explode("\r\n",file_get_contents("s.txt"));
$conn = pg_connect("host=192.168.0.11 port=5432 dbname=search_114 user=pgsql password=imslimsl");

echo "<li class=\"\""." onclick=\"javascript:document.getElementById('keyword').value='$cfdd';gsc_hide(document.getElementById('search-results'));\"   onmouseover=\"this.className='ac_over';\"  onmouseout=\"this.className='';\"    ";
echo "<li class=\"\""." onclick=\"javascript:document.getElementById('keyword').value='$cfdd';gsc_hide(document.getElementById('search-results'));\"   onmouseover=\"this.className='ac_over';\"  onmouseout=\"this.className='';\"    ";
echo "<li class=\"\""." onclick=\"javascript:document.getElementById('keyword').value='$cfdd';gsc_hide(document.getElementById('search-results'));\"   onmouseover=\"this.className='ac_over';\"  onmouseout=\"this.className='';\"    ";
		  .">$cfdd</li>";
function busc($bu){
if (($bu=="") || ($bu==" ") || strlen($bu)<='2' ){
	return  "";
}else{
	$list = get_tmp_list($bu,$cl,$index);
	$z=0;
	$sa="<ul>";
	foreach($list as $row) {
	$cfdd = $row["nn"];
	$sa.="<li class=\"\""." onclick=\"javascript:document.getElementById('keyword').value='$cfdd';gsc_hide(document.getElementById('search-results'));\"   onmouseover=\"this.className='ac_over';\"  onmouseout=\"this.className='';\"    "
		  .">$cfdd</li>";
		 $z++;
		 if($z=="20") break;
	 }//endwhile
	 $sa.="</ul>";
	return $sa;
 }
}



function get_tmp_list($keyword){
//global $cl,$index;

/*sphinxapi*/
require ( "sphinxapi.php" );
$mode = SPH_MATCH_ANY;
$host = "localhost";
$port = 3312;
$index = "test1";
$groupby = "";
$groupsort = "@group desc";
$filter = "id";
$filtervals = array();
$distinct = "";
$sortby = "";
$limit = 100;
$ranker = SPH_RANK_BM25;

$cl = new SphinxClient ();
$cl->SetServer ( $host, $port );
$cl->SetConnectTimeout ( 1 );
$cl->SetFieldWeights ( array ( 'u_py'=>200) );
$cl->SetMatchMode ( $mode );
$cl->SetRankingMode ( $ranker );
$cl->SetArrayResult ( true );


$q =$keyword;
$full_q = preg_replace("/\s+/","",$q);
$res = $cl->Query($full_q, $index );
$matches = $res["matches"];
foreach($matches as $match){
	$mm[]=$match["id"];
}
$q =preg_replace("/\s+/"," ",$q);
$res = $cl->Query ($q, $index );
$matches = $res["matches"];
foreach($matches as $match){
	$mm[]=$match["id"];
	$mark[]=$match["weight"];
}

$q =preg_replace("/\s+/","|",$q);
$res = $cl->Query ($q, $index );
$matches = $res["matches"];
foreach($matches as $match){
	$mm[]=$match["id"];
	$mark[]=$match["weight"];
}
//print_r($mark);
//
/*$conn = pg_connect("host=192.168.0.11 port=5432 dbname=search_114 user=pgsql password=imslimsl");
$sql="select id,corp_name ,full_pinyin,u_py from name_list_all where id in (".implode(",",$mm).") ";
$rt = pg_query($sql);
while($row = pg_fetch_array($rt)){
	//$list[$row[id]]=$row["corp_name"];
	$list[$row[id]]=$row;
	//echo $row["id"]."=>".$row["corp_name"]."<br>";
}
*/
	$sql="select id,corp_name,name_letter from name_list_all where id in (".implode(",",$mm).") ";
	//echo $sql;
	$rt = pg_query($sql);
	while($row = pg_fetch_array($rt)){
		$list[$row[id]]=$row["corp_name"];
		$letter[$row[id]]=$row["name_letter"];
	}
	$keywords = "(".preg_replace("/\s+/","|",$keyword).")";
	foreach($mm as $id){
		preg_match($keywords,$letter[$id],$out);
		$sa = $out[0];
		$pos = strpos($letter[$id],$sa);
		$rt_list[$id]["nn"]=$list[$id];
	}

	return $rt_list;
}


?>