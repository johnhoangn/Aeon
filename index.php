<?php
	$operation = $_POST["op"];
	$db = new mysqli("localhost","id2146451_kickedbla","sxfbke1999","id2146451_aeonmaster");
	if(mysqli_connect_errno()){
		echo(mysqli_connect_error());
	}
	
	if(strcmp($operation,"setParty")==0){
		$roster = $_POST["roster"];
		$pass = $_POST["password"];
		if ($pass!=null && strcmp($pass,"sxfbke1999"==0)){
			$success = $db->query("INSERT INTO `Parties` (`members`) VALUES ('$roster')");
			if($success==true){
				$result = $db->query("SELECT * FROM `Parties` WHERE `members`='$roster'");
				$row = $result->fetch_assoc();
				echo($row["partyId"]);
			}
			else
				echo("Failed");
		}
	}elseif(strcmp($operation,"getPartyId")==0){
		$id = $_POST["id"];
		$result = $db->query("SELECT * FROM `Parties` WHERE `members` LIKE '%[$id%]'");
		if($result->num_rows > 0){
			$row = $result->fetch_assoc();
			echo($row["partyId"]);
		}else
			echo("No Party");
	}elseif(strcmp($operation,"getParty")==0){
		$id = $_POST["id"];
		$result = $db->query("SELECT * FROM `Parties` WHERE `partyId`=$id");
		if($result->num_rows > 0){
			$row = $result->fetch_assoc();
			echo($row["members"]);
		}else
			echo("No Party");
	}elseif(strcmp($operation,"updateParty")==0){
		$id = $_POST["id"];
		$pass = $_POST["password"];
		$roster = $_POST["roster"];
		if ($pass!=null && strcmp($pass,"sxfbke1999"==0)){
			$success = $db->query("UPDATE `Parties` SET `members`='$roster' WHERE `partyId`=$id");
			echo($success);
		}
	}elseif(strcmp($operation,"disbandParty")==0){
		$id = $_POST["id"];
		$pass = $_POST["password"];
		if ($pass!=null && strcmp($pass,"sxfbke1999"==0)){
			$success = $db->query("DELETE FROM `Parties` WHERE `partyId`=$id");
			$db->query("OPTIMIZE TABLE  `Parties`");
		}
	}	
?>
