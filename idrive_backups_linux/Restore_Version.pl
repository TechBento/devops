#!/usr/bin/perl
require 'header.pl';

use File::Path;
use Constants 'CONST';

# $appTypeSupport should be ibackup for ibackup and idrive for idrive#
# $appType should be IBackup for ibackup and IDrive for idrive        #
my ($appTypeSupport,$appType) = getAppType();

getParameterValue(\"PVTKEY", \$hashParameters{PVTKEY});
my $pvtKey = $hashParameters{$pvtParam};
if(! -e $pwdPath or ($pvtKey ne "" and ! -e $pvtPath)){
	print CONST->{'PlLogin'}.$whiteSpace.$appType.$whiteSpace.CONST->{'AccLogin'}.$lineFeed;
	system("/usr/bin/perl logout.pl 1"); 
	exit(1);
} 

my $lastVersion = undef;

# Trace Log Entry #
my $curFile = basename(__FILE__);
print $tHandle "$lineFeed File: $curFile $lineFeed",
		"---------------------------------------- $lineFeed";
		
displayMainMenu();
getMainMenuChoice();
getFilePath();
doMainOperation();

#**********************************************************************************
# Subroutine Name         : displayMainMenu.
# Objective               : Subroutine to display Main Menu.
# Added By                : Dhritikana Kalita.
#**********************************************************************************
sub displayMainMenu {
	system("clear");
	print $whiteSpace.CONST->{'DisplayVer'}.$lineFeed;
	print $whiteSpace.CONST->{'RestoreVer'}.$lineFeed;
}

#**********************************************************************************
# Subroutine Name         : getMainMenuChoice.
# Objective               : Subroutine to get Main Menu choice from user.
# Added By                : Dhritikana Kalita.
#**********************************************************************************
sub getMainMenuChoice {
	while(!defined $mainMenuChoice) {
		print $lineFeed.$whiteSpace.CONST->{'EnterChoice'}.$lineFeed.$whiteSpace;
		$mainMenuChoice = <>;
		chomp($mainMenuChoice);
		
		if($mainMenuChoice =~ m/^\d$/) {
			if($mainMenuChoice < 1 || $mainMenuChoice > 2) {
				$mainMenuChoice = undef;
				print $lineFeed.$whiteSpace.CONST->{'InvalidChoice'}.$whiteSpace.CONST->{'TryAgain'}.$lineFeed;
			} 
		}
		else {
			$mainMenuChoice = undef;
		}
	}
}

#***********************************************************************************************************
# Subroutine Name         : getFilePath.
# Objective               : Ask user for the file path for which he/she wants to do dispay/restore file version.
# Added By                : Dhritikana Kalita.
#**********************************************************************************************************
sub getFilePath {
	system("clear");
	print $lineFeed.$whiteSpace.CONST->{'AskFilePath'}.$lineFeed.$whiteSpace;
	$filePath = <STDIN>;
	chomp($filePath);
	$filePath =~ s/^\s+|\s+$//g;
	
	if(substr($filePath, 0, 1) ne "/") {
		$fullFilePath = $restoreHost."/".$filePath;
	} else {
		$fullFilePath = $restoreHost.$filePath;
	}
}

#*************************************************************************************************
# Subroutine Name         : doMainOperation.
# Objective               : Based on user's request, call restore function to perform restore job
# Added By                : Dhritikana Kalita.
#*************************************************************************************************
sub doMainOperation {
	if($mainMenuChoice eq 1) {
		displayVersions();
		print $lineFeed.$whiteSpace.CONST->{'AskRestoreVer'}.$lineFeed;

		getConfirmationChoice();
		if($confirmationChoice eq "N" || $confirmationChoice eq "n") {
			print $whiteSpace.CONST->{'Exit'}.$lineFeed;
			unlink($idevsErrorFile);
			exit 0;
		} 
	} else {
		itemStat();
	}

	createRestoresetFile();
	restoreVersion();
	unlink($idevsErrorFile);
}

#********************************************************************************
# Subroutine Name         : displayVersions.
# Objective               : Display versions of user's requested file
# Added By                : Dhritikana Kalita.
#********************************************************************************
sub displayVersions {
	my $versionUtfFile = getOperationFile($versionOp, $fullFilePath);
	chomp($versionUtfFile);
	$versionUtfFile =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$versionUtfFile."'".$whiteSpace.$errorRedirection;;
	my $commandOutput = `$idevsutilCommandLine`;
	unlink $versionUtfFile;
	system("clear");
	
	my @commandOutput = split("\n", $commandOutput);
	for (@commandOutput[1 .. $#commandOutput]) {
		print " ".$_."\n";
	}
	
	if($commandOutput =~ /path not|No version/) {
		unlink($idevsErrorFile);
		print $lineFeed.$whiteSpace.CONST->{'Exit'}.$lineFeed;
		exit;
	}
	
	$lastVersion = substr($commandOutput[-1], -4, -1);
}

#********************************************************************************
# Subroutine Name         : itemStat.
# Objective               : Check if file exits
# Added By                : Dhritikana Kalita.
#********************************************************************************
sub itemStat {
	open TEMP, ">stat.txt" or print $tHandle CONST->{'FileOpnErr'}.", Resaon: $!".$lineFeed;
	print TEMP $fullFilePath;
	close TEMP;
	chmod 0777, "stat.txt";
	
	my $itemStatUtfFile = getOperationFile($itemStatOp, "stat.txt");
	chomp($itemStatUtfFile);
	$itemStatUtfFile =~ s/\'/\'\\''/g;
	
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$itemStatUtfFile."'".$whiteSpace.$errorRedirection;;
	my $commandOutput = `$idevsutilCommandLine`;
	unlink $itemStatUtfFile;
	unlink("stat.txt");
	system("clear");
	
	if($commandOutput =~ /No such file or directory|directory exists/) {
		print $lineFeed.$whiteSpace.CONST->{'NonExist'};
		print $lineFeed.$whiteSpace.CONST->{'Exit'}.$lineFeed;
		print $tHandle $lineFeed."Restore Version: item stat: $commandOutput".$lineFeed;
		exit;
	}
}


#*************************************************************************************************
# Subroutine Name         : createRestoresetFile.
# Objective               : create RestoresetFile based on user's given version number.
# Added By                : Dhritikana Kalita.
#*************************************************************************************************
sub createRestoresetFile {
		print $lineFeed.$whiteSpace.CONST->{'AskVersion'}.$lineFeed.$whiteSpace;
		$versionNo = <STDIN>;
		
		while($mainMenuChoice == 1 && $versionNo > $lastVersion or $versionNo < 1) {
				print $lineFeed.$whiteSpace.CONST->{'InvalidVersion'}.$lineFeed.$whiteSpace;
				print $lineFeed.$whiteSpace.CONST->{'AskVersion'}.$lineFeed.$whiteSpace;
				$versionNo = <STDIN>;
		}
		while($mainMenuChoice == 2 && $versionNo > 30 or $versionNo < 1) {
				print $lineFeed.$whiteSpace.CONST->{'InvalidVersion'}.$lineFeed.$whiteSpace;
				print $lineFeed.$whiteSpace.CONST->{'AskVersion'}.$lineFeed.$whiteSpace;
				$versionNo = <STDIN>;
		}
		
		$versionNo =~ s/^\s+//g;
		chomp($versionNo);
		
		$jobRunningDir = $currentDir."/user_profile/".$userName."/Restore/Manual";
		if(!-d $jobRunningDir) {
			mkpath($jobRunningDir);
		}	
		chmod 0777, $jobRunningDir;
		
		my $restoresetFile = $jobRunningDir."/versionRestoresetFile.txt";
		
		open(FILE, ">", $restoresetFile) or print $tHandle "Couldn't open $restoresetFile for restoreVersion option. Reason: $!\n";
		chmod 0777, $restoresetFile;
			print FILE $fullFilePath."_IBVER".$versionNo.$lineFeed;
		close(FILE);
}

#********************************************************************************
# Subroutine Name         : restoreVersion.
# Objective               : Restore user's requested version of a file
# Added By                : Dhritikana Kalita.
#********************************************************************************
sub restoreVersion {
	print $lineFeed.$whiteSpace.CONST->{'RestoreOpStart'}.$lineFeed;
	my $restoreRunCommand = "perl Restore_Script.pl 2";
	my @res = `$restoreRunCommand`;
	foreach(@res) {
		if($_ !~ /\idevs error\:/) {
			print $_;
		} else {
			print $tHandle $_."\n";
			last;
		}		

	}
	unlink("$jobRunningDir/versionRestoresetFile.txt");
}

#****************************************************************************************************
# Subroutine Name         : getConfirmationChoice.
# Objective               : This subroutine gets the user input for (YES/NO) option.
# Added By                : 
#*****************************************************************************************************/
sub getConfirmationChoice {
	while(!defined $confirmationChoice) {
		print $whiteSpace.CONST->{'EnterChoice'}.$whiteSpace;
		
		$confirmationChoice = <>;
		chop $confirmationChoice;
		
		$confirmationChoice =~ s/^\s+//;
		$confirmationChoice =~ s/\s+$//;
		
		if($confirmationChoice =~ m/^\w$/ && $confirmationChoice !~ m/^\d$/) {
			if($confirmationChoice eq "y" ||
				$confirmationChoice eq "Y" ||
				$confirmationChoice eq "n" ||
				$confirmationChoice eq "N") {
			}
			else {
				$confirmationChoice = undef;
				print $whiteSpace.CONST->{'InvalidChoice'}.$whiteSpace;
			} 
		}
		else {
			$confirmationChoice = undef;
			print $whiteSpace.CONST->{'InvalidChoice'}.$whiteSpace;
		}
	}
	  
	print "\n";
}
