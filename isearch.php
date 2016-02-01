<?
//定义根目录
define("_ROOT",".");
//引入配置文件
include "config.inc.php";
//获得提交过来的关键词
$keyword = $_GET["keyword"];
if($keyword){
	$keyword = strtolower($keyword); 
	//命令
	$cmd = "perl ./iSearch.pl $keyword";
	#die($cmd);
	//运行命令
	$mk = 0;
	//将search.pl的排序结果，赋值给$num
	$result = @exec($cmd,$out);
	$num_result = preg_split("/\s+/",$result); 
	//对out进行分类和处理
	foreach($out as $o){
		$mk++;
		//rank	name	score
		
		$os = preg_split("/\s+/",$o);
		//print "$os[0] - $os[1] - $os[2] <br>";
		//$oname = $os[4];
		//$os[3] = $os[3];
		//if($oname =="exact" ) $os[2] = highlighta($okeyword,$os[2],$os[3]);
		//$aalist[$oname][] = $os;
		$aalist["match"][] = $os;
		
	}
	//模板赋值
	//$aalist["obscur"] = array_slice($aalist["obscur"],0,100);
	//$aalist["exact"] = array_slice($aalist["exact"],0,100);
	$aalist["match"] = array_slice($aalist["match"],0,100);
	$smarty->assign("alist",$aalist["match"]);
	//$smarty->assign("alist",$aalist["exact"]);
	//$smarty->assign("blist",$aalist["obscur"]);
	$smarty->assign("kk",$num_result[0]);
	$smarty->assign("list",$name_l);
	$smarty->assign("count",$num);
	$smarty->assign("page_title","编码检索");
	//模板显示
	$smarty->display("html/search.html");

}


/*获得当前系统时间*/
function getmicrotime(){
	list($usec, $sec) = explode(" ",microtime());
	return ((float)$usec + (float)$sec);
}
/*对结果进行高亮显示*/
function highlighta($keyword,$corp_name,$name_letter){
	$kk = preg_split("/\s+/",$keyword);
	$acorp_name = $corp_name;
	foreach($kk as $key=>$vv){
		$start = strpos($name_letter,$vv);
			$len = strlen($vv);
			$x_str= mb_substr($corp_name,$start,$len,"UTF-8");
			$acorp_name = str_replace($x_str,"<font color=red>".$x_str."</font>",$acorp_name);
	}
	return $acorp_name;
}
/*对关键词进行二元分词*/
function bigram($str,$sp="|"){
	for($i=0;$i<(strlen($str)-1);$i++){
		if($i>0) $astr.=$sp;
		$astr.=substr($str,$i,2);
	}
	return $astr;
}
?>

