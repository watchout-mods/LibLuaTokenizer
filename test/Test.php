<?php
error_reporting(E_ALL);

#system("lua Main.lua < Main.lua | tee");
system("lua Main.lua < Test.lua | tee");

#echo file_get_contents("Test.html");

?>