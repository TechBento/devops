#!/usr/bin/perl
require 'header.pl';
use FileHandle;

use constant false => 0;
use constant true => 1;

use Constants 'CONST';

#File name of file which stores backup progress information   #
my $menuChoice = undef;
my $jobType = undef;
my $Pflag = undef;
my $taskType = "SCHEDULE";
my $progressDetailsFilePath = undef;
my $prevLine = undef;

#A check if User has logged in or not   #
my ($appTypeSupport,$appType) = getAppType();
if(!($ARGV[0])) {
	my $pvtParam = "PVTKEY";
	getParameterValue(\$pvtParam, \$hashParameters{$pvtParam});
	my $pvtKey = $hashParameters{$pvtParam};
	if(! -e $pwdPath or ($pvtKey ne "" and ! -e $pvtPath)){
		print CONST->{'PlLogin'}.$whiteSpace.$appType.$whiteSpace.CONST->{'AccLogin'}.$lineFeed;
        system("/usr/bin/perl logout.pl 1");
        exit(1);
	}
}

my $BackupScriptCmd = "ps -elf | grep \"Backup_Script.pl Backup $userName\" | grep -v cd | grep -v grep";
my $RestoreScriptCmd = "ps -elf | grep \"Restore_Script.pl Restore $userName\" | grep -v cd | grep -v grep";
$BackupScriptRunning = `$BackupScriptCmd`;
$RestoreScriptRunning = `$RestoreScriptCmd`;

if($BackupScriptRunning ne "" && $RestoreScriptRunning ne "") {
	printMenu();	
	$menuChoice = getMenu();
	if($menuChoice eq 1) {
		$jobType = "BACKUP";
	} elsif($menuChoice eq 2) {
		$jobType = "RESTORE";
	}
} elsif($BackupScriptRunning ne "") {
	$jobType = "BACKUP";
} elsif($RestoreScriptRunning ne "") {
	$jobType = "RESTORE";
} else {
	print CONST->{'NoOpRng'}.$lineFeed; 
	exit;
}

#Subroutine that processes SIGINT and SIGTERM signal received by the script#
$SIG{INT} = \&process_term;
$SIG{TERM} = \&process_term;
$SIG{TSTP} = \&process_term;
$SIG{QUIT} = \&process_term;

#A check if User has logged in or not   #
my ($appTypeSupport,$appType) = getAppType();
my $pvtParam = "PVTKEY";
getParameterValue(\$pvtParam, \$hashParameters{$pvtParam});
my $pvtKey = $hashParameters{$pvtParam};
#if(! -e $pwdPath or ($pvtKey ne "" and ! -e $pvtPath)){
#		print CONST->{'PlLogin'}.$appType.CONST->{'AccLogin'}.$lineFeed;
#        system("/usr/bin/perl logout.pl 1");
#        exit(1);
#}

# Trace Log Entry #
my $curFile = basename(__FILE__);
print $tHandle "$lineFeed File: $curFile $lineFeed",
                "---------------------------------------- $lineFeed";

constructProgressDetailsFilePath();

system("clear");
my $diplayHeader =  "----------------$taskType $jobType PROGRESS--------------------------------------\n".
				 "---------------------------------------------------------------------------------\n".
				"FILE NAME | FILE SIZE |  $jobType"."SET SIZE | TRANSFER RATE | PERCENTAGE | PROGRESS \n".
				 "---------------------------------------------------------------------------------\n";
print $diplayHeader;
do {
	do {
		my $lastLine = readProgressDetailsFile();
		if($lastLine ne "" && $lastLine ne $prevLine) {
			my @params = split( /$whiteSpace+/, $lastLine);
			$percentageComplete = $params[1];
			
			$lineFeedPrinted = false;
			displayProgressBar($params[0], $params[1], $params[2], $params[3], $params[4]);
			$prevLine = $lastLine;
			
			#if($lastLine =~ "END_OF_PROCESS") {
			#	print "============END OF PROCESS============\n";
			#	exit(1);
			#} 
		}
		select undef, undef, undef, 0.005;
	}
	while(defined $percentageComplete and $percentageComplete <= 100);
}
while(1);

#****************************************************************************************************
# Subroutine Name         : printMenu.
# Objective               : Subroutine to print options to do status Retrival.
# Modified By             : Dhritikana
#*****************************************************************************************************/
sub printMenu {
	system("clear");
	print $lineFeed.$whiteSpace.CONST->{'BothRunning'}.$lineFeed;
	print $lineFeed.$whiteSpace.CONST->{'AskStatusOp'}.$lineFeed;
  	print $lineFeed;
  	print $lineFeed.$whiteSpace.CONST->{'StatBackOp'}.$whiteSpace.$lineFeed;
  	print $lineFeed.$whiteSpace.CONST->{'StatRstOp'}.$whiteSpace.$lineFeed;
  	print $lineFeed.$lineFeed;
}

#****************************************************************************************************
# Subroutine Name         : getMenu.
# Objective               : Subroutine to get option to do status Retrival
# Added By                : 
#*****************************************************************************************************/
sub getMenu {
	while(!defined $menuChoice) {
		$menuChoice = <STDIN>;
		chomp($menuChoice);
	}
	return $menuChoice;
}
 
#****************************************************************************************************
# Subroutine Name         : constructProgressDetailsFilePath.
# Objective               : This subroutine frames the path of Progress Details file.
# Modified By             : Dhritikana
#*****************************************************************************************************/
sub constructProgressDetailsFilePath {
    my $wrokginDir = $currentDir;
    $wrokginDir =~ s/ /\ /g;
    
    $progressDetailsFilePath = $usrProfileDir.$pathSeparator."PROGRESS_DETAILS_".$jobType;
}

#****************************************************************************************************
# Subroutine Name         : readProgressDetailsFile.
# Objective               : This subroutine reads the last line of Progress Details file. It then 
#							parses the line to extract the filename and the backup progress for that file. 
# Modified By             : Dhritikana
#*****************************************************************************************************/
sub readProgressDetailsFile {
	open PROGRESS_DETAILS_FILE, "<", $progressDetailsFilePath or (print $tHandle "$lineFeed ProgressDetails File does not exist :$! $lineFeed" or die);
	
	my $lastLine = <PROGRESS_DETAILS_FILE>;
	chomp($lastLine);

	close PROGRESS_DETAILS_FILE;
	
	my @Params = split /$whiteSpace+/, $lastLine;
	my $percentCompleteArr = $Params[1];
	
	if($percentCompleteArr eq "") {
		return "";
	}
	else { 
		return $lastLine;
	}
}

#****************************************************************************************************
# Subroutine Name         : process_term.
# Objective               : In case the script execution is canceled by the user,the script should exit.
#							bar in the terminal window.
# Added By                : 
#*****************************************************************************************************/
sub process_term {
  exit 0;
}
