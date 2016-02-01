<?php

// put full path to Smarty.class.php
require('Smarty/libs/Smarty.class.php');
$smarty = new Smarty();

$smarty->setTemplateDir('/home/wei/public_html/site_115/templates');
$smarty->setCompileDir('/home/wei/public_html/site_115/templates_c');
$smarty->setCacheDir('/home/wei/public_html/site_115/cache');
$smarty->setConfigDir('/home/wei/public_html/site_115/configs');

$smarty->assign('name', 'Ned');
$smarty->display('index.tpl');

?>
