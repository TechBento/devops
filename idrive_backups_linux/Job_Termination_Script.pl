#!/usr/bin/perl

require 'header.pl';
use Constants 'CONST';

my $mainMenuChoice = undef;
my $scriptName = ""; #script name
my $statusScriptName = "Status_Retrieval_Script.pl"; #Status Retrieval script name#
my $statusScriptRunning = ""; #If status retrieval script is executing#
my $scriptCmd = undef;

#A check if User has logged in or not   #
my ($appTypeSupport,$appType) = getAppType();
if(!($ARGV[0])) {
	my $pvtParam = "PVTKEY";
	getParameterValue(\$pvtParam, \$hashParameters{$pvtParam});
	my $pvtKey = $hashParameters{$pvtParam};
	if(! -e $pwdPath or ($pvtKey ne "" and ! -e $pvtPath)) {
		print CONST->{'PlLogin'}.$whiteSpace.$appType.$whiteSpace.CONST->{'AccLogin'}.$lineFeed;
        system("/usr/bin/perl logout.pl 1");
        exit(1);
	}
}

# Trace Log Entry #
my $curFile = basename(__FILE__);
print $tHandle "$lineFeed File: $curFile $lineFeed", 
                "---------------------------------------- $lineFeed";
   
if($ARGV[0]) {
	chomp($ARGV[0]);
	if($ARGV[0] eq "Backup") {
		$mainMenuChoice = 1;
	} elsif ($ARGV[0] eq "Restore") {
		$mainMenuChoice = 2;
	} elsif($ARGV[0] eq "retryExit") {
		$mainMenuChoice = "retryExit";
	}
	
	$userName = $ARGV[1];
	if(!$userName) {
		print $tHandle "Username for schedule job paramater is missing\n";
		print "Username for schedule job paramater is missing\n";
		exit(1);
	}
} else {
	printMenu();
	getMenuChoice();
}

if($mainMenuChoice eq 1) {
	$scriptName = "Scheduled Backup job";
	$jobRunningDir = "$usrProfilePath/$userName/Backup/Scheduled/";
}elsif($mainMenuChoice eq 2) {
	$scriptName = "Scheduled Restore job";
	$jobRunningDir = "$usrProfilePath/$userName/Restore/Scheduled/";
}elsif($mainMenuChoice eq 3) {
	$scriptName = "Manual Backup job";
	$jobRunningDir = "$usrProfilePath/$userName/Backup/Manual/";
}elsif($mainMenuChoice eq 4) {
	$scriptName = "Manual Restore job";
	$jobRunningDir = "$usrProfilePath/$userName/Restore/Manual/";
}elsif($mainMenuChoice eq "retryExit") {
	$scriptName = "$jobType job";
	$jobRunningDir = $ARGV[2]."/";
} else {
	print CONST->{'InvalidChoice'}.$lineFeed;
	exit(1);
}

my $pidPath = $jobRunningDir."pid.txt";
my $utfFile = $jobRunningDir."utf8.txt";
my $searchUtfFile = undef;
if($scriptName =~ /Restore/) {
	$searchUtfFile = $jobRunningDir."searchUtf8.txt";
}

killRunningScript();
killStatusScript();

#****************************************************************************************************
# Subroutine Name         : printMenu.
# Objective               : Subroutine to print Main Menu choice. 
# Added By                : 
#*****************************************************************************************************/
sub printMenu()
{
	system("clear");
	
	print $lineFeed.$whiteSpace.CONST->{'AskOption'}.$whiteSpace.$lineFeed;
	print $whiteSpace.$lineFeed;
	print $whiteSapce."1. Kill Scheduled Backup Job\n";
	print $whiteSapce."2. Kill Scheduled Restore Job\n";
	print $whiteSapce."3. Kill Manual Backup Job\n";
	print $whiteSapce."4. Kill Manual Restore Job\n";
	print $whiteSpace.$lineFeed;
}

#****************************************************************************************************
# Subroutine Name         : getMenuChoice.
# Objective               : Subroutine to get Main Menu choice from user. 
# Added By                : 
#*****************************************************************************************************/
sub getMenuChoice()
{
  	while(!defined $mainMenuChoice)
  	{
		$mainMenuChoice = <STDIN>;
		chomp($mainMenuChoice);
	}
}

#****************************************************************************************************
# Subroutine Name         : killRunningScript.
# Objective               : Command to check if scripts are executing. 
# Added By                : 
#*****************************************************************************************************/
sub killRunningScript 
{
	my $evsCmd = "ps -elf | grep \"$currentDir/idevsutil\" | grep \'$utfFile\'";
	$evsRunning = `$evsCmd`;
	
	if($scriptName =~ /Restore/) {
		$evsCmd = "ps -elf | grep \"$currentDir/idevsutil\" | grep \'$searchUtfFile\'";
		$evsRunning .= `$evsCmd`;
	}

	@evsRunningArr = split("\n", $evsRunning);
	my $jobCount = 0;
	my @pids;
	
	foreach(@evsRunningArr) {
		if($_ =~ /$evsCmd/) {
			next;
		}
		my @lines = split(/[\s\t]+/, $_);
		my $pid = $lines[3];
		push(@pids, $pid);
	}
	
	chomp(@pids);
	s/^\s+$// for (@pids);
	$jobCount = @pids;
	
	if($jobCount eq 0) {
		print $scriptName.$whiteSpace.CONST->{'NotRng'}.$lineFeed; 	
		exit 0;
	}

	my $pidString = join(" ", @pids);

	my $scriptTermCmd = "kill -9 $pidString";
	$scriptTerm = system($scriptTermCmd);

	if($scriptTerm != 0) {
		print CONST->{'KilFail'}.$scriptName.$lineFeed;
		print $tHandle CONST->{'KilFail'}.$scriptName.$lineFeed;
	}
	elsif($scriptTerm  == 0) {
		print CONST->{'KilSuccess'}.$scriptName.$lineFeed;
		unlink($pidPath);
	}		
}

#****************************************************************************************************
# Subroutine Name         : killStatusScript.
# Objective               : If status retrieval script is running, then terminate status retrieval script. 
# Added By                : 
#*****************************************************************************************************/
sub killStatusScript 
{
	#Command to check if status retrieval script is executing #
	my $statusScriptCmd = "ps -elf | grep $statusScriptName | grep -v grep";
	$statusScriptRunning = `$statusScriptCmd`;
	
	if($statusScriptRunning ne "") {
		my @processValues = split /[\s\t]+/, $statusScriptRunning;
		my $pid = $processValues[3];  
		my $statusScriptTermCmd = "kill -s SIGTERM $pid";
		my $statusScriptTerm = system($statusScriptTermCmd);
		
		if($statusScriptTerm != 0) {
			print $tHandle CONST->{'KilFail'}.$statusScriptName."$statusScriptTerm ".$lineFeed;
		}
	}
}

