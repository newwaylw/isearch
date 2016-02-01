<?
//定义根目录
define("_ROOT",".");
//引入配置文件
include "config.inc.php";
//随即查询30条记录，显示在首页
$sql="select corp_name from $table_name order by random() limit 30";
$rt = pg_query($sql);
while($row = pg_fetch_array($rt)){
	$name_l .= $row["corp_name"]."&nbsp;&nbsp;";
	//echo "$name_l<br>";
}
//模板赋值

// create object
//$smarty = new template;
//$smarty->testInstall();
$smarty->assign("alist",$alist);
$smarty->assign("kk",$okeyword);
$smarty->assign("list",$name_l);
$smarty->assign("count",$num);
$smarty->assign("page_title","名称检索");

//$smarty->compile_check = true; 
//$smarty->debugging = true; 
#echo "模板显示";
$smarty->display("html/index.html");
?>
