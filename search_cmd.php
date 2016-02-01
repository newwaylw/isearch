<?
//定义根目录
define("_ROOT",".");
//引入配置文件
include "config.inc.php";
//获得提交过来的关键词
//$keyword = $_GET["keyword"];
$keyword = $argv[1];
if($keyword){
	//如果有关键词
	//转成大写
	//$keyword = iconv("GB2312","UTF-8",$keyword);
	//提取其中的中文字符，并替换为空
	$oo_keyword = $keyword;
	$pregstr = "/([\x{4e00}-\x{9fa5}]{1})/u";
	preg_match_all($pregstr,$keyword,$out);
	foreach($out[1]  as $cw){
		$keyword = str_replace($cw,"",$keyword); // replace every $cw with empty in $keyword
		$ckeyword .=$cw." ";   //ckeyword is chinese characters input as part of some keyword
	}
	$keyword = trim( strtolower($keyword) );
	$ckeyword = trim($ckeyword);
	//构造sql语句
	if($ckeyword>""){
		$ckeyword = str_replace(" ","&",$ckeyword);
		$cstr = " and to_tsquery('$ckeyword') @@ word_idx ";
	}
	$okeyword = $keyword;
	$s_keyword = preg_replace("/\s+/","|",preg_replace("/\s+/","",$keyword)." ".$okeyword);
	$keyword=preg_replace("/\s+/","",$keyword);
	//cache file
	$f_name  = "./cache/".md5($okeyword).".txt";
	//判断是否有缓存文件
	if(!file_exists($f_namea)){
		//没有缓存文件
		//对关键词进行二元分词
	$qq = bigram($keyword);
	//查询sql
	$t_start = microtime(true);
	$sql="select id, corp_name, name_letter, u_py, t_py, s_py, p_py, u_name, t_name, s_name, p_name   FROM $table_name ,to_tsquery('$s_keyword') query ,to_tsquery('$qq') query2 WHERE query2 @@ name_letter_idx $cstr ORDER BY (ts_rank(u_py_idx, query)*5+ts_rank(t_py_idx, query)+ts_rank(s_py_idx, query)+ts_rank(p_py_idx, query)+ts_rank(name_letter_idx, query2)*5 )  DESC limit 1000 ";
	$rt= pg_query($sql);
	$t_end = microtime(true) - $t_start;

	echo "SQL query time: $t_end </br>";
	//返回排名前1000的结果
	while($l=pg_fetch_array($rt,NULL,PGSQL_ASSOC)){
		foreach($l as $kk=>$ll){
			$l[$kk] = trim($ll);
			
		}
		$ss.=implode(",",$l)."\r\n";
		$j++;
		if($j>1000) break;
		
	}
	//写入临时文件，让search.pl去排序
        //print "writing to $f_name<br>";
	file_put_contents($f_name,$ss);

	}else{
	//
	}
	//search.pl排序
	$argv1 = $f_name;
	$argv2 = "result.txt";
	//命令
	$cmd = "perl ./data/search.pl $argv1  $argv2  $okeyword 2>&1";
	
	//die($cmd);
	//运行命令
	$mk = 0;
	//将search.pl的排序结果，赋值给$out
	@exec($cmd,$out);
	//对out进行分类和处理
	foreach($out as $o){
		$mk++;
		$o = $mk." ".iconv("GB2312","UTF-8",$o);
		$os = preg_split("/\s+/",$o);
		$oname = $os[4];
		$os[3] = $os[3];
		if($oname =="exact" ) $os[2] = highlighta($okeyword,$os[2],$os[3]);
		$aalist[$oname][] = $os;
		
	}
	//模板赋值
	$aalist["obscur"] = array_slice($aalist["obscur"],0,100);
	$aalist["exact"] = array_slice($aalist["exact"],0,100);
	$smarty->assign("alist",$aalist["exact"]);
	$smarty->assign("blist",$aalist["obscur"]);
	$smarty->assign("kk",$oo_keyword);
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
