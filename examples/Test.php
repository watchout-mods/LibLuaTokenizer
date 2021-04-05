<?php
error_reporting(E_ALL);

#system("lua Main.lua < Main.lua | tee");
system("lua Main.lua < Test.lua | tee");
#system("lua Main.lua < ..\\LuaTokenizer-1.0.lua");

#echo file_get_contents("Test.html");

?>