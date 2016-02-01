<?
			require_once(_ROOT."/Smarty/libs/Smarty.class.php");
			//$smarty = new template;
			$smarty = new Smarty();
			//require_once(_ROOT."/class/smarty/Smarty.class.php");
			//$smarty = new Smarty ;
			$smarty->error_level="1"; //0
			$smarty->debugging=1;
			$smarty->caching= false;
			$smarty->compile_check = true;
			$smarty->security=true;
			$smarty->left_delimiter  =  '{%';
			$smarty->right_delimiter =  '%}';
			$smarty->template_dir=_ROOT;
			$smarty->compile_dir = _ROOT."/temp";
//			$smarty->assign("root",PLUS_URL);
			$smarty->assign("now",date("Y-m-d H:i:s"));
?>
