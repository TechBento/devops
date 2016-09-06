#!/usr/bin/perl
require 'header.pl';
use File::Copy;

use constant false => 0;
use constant true => 1;

use Constants 'CONST';

#Whether the Scheduler script is invoked by the user or by the backup script#
my $invokedScript = false;
my $terminateHour = undef;
my $terminateMinute = undef;
my $selectJobTermination = undef;
my $editFlag = undef;
my $noRoot = 0;
my $rmFlag = 0;
#my @modifiedLinesCrontab = undef;
my $user = undef;
my $scheduleMsg = undef;

#A check if User has logged in or not   #
my ($appTypeSupport,$appType) = getAppType();
my $pvtParam = "PVTKEY";
getParameterValue(\$pvtParam, \$hashParameters{$pvtParam});
my $pvtKey = $hashParameters{$pvtParam};
if(! -e $pwdPath or ($pvtKey ne "" and ! -e $pvtPath)) {
		print CONST->{'PlLogin'}.$whiteSpace.$appType.$whiteSpace.CONST->{'AccLogin'}.$lineFeed;
		system("/usr/bin/perl logout.pl 1");
        exit(1);
}

##############################################
#Subroutine that processes SIGINT and SIGTERM#
#signal received by the script during backup #
##############################################
$SIG{INT} = \&cancelProcess;
$SIG{TERM} = \&cancelProcess;
$SIG{TSTP} = \&cancelProcess;
$SIG{QUIT} = \&cancelProcess;

# Trace Log Entry #
my $curFile = basename(__FILE__);
print $tHandle "$lineFeed File: $curFile $lineFeed",
                "---------------------------------------- $lineFeed";

if($#ARGV + 1 == 2) {
  $invokedScript = true;
}

my $workingDir = $currentDir;

$workingDir =~ s/\'/\'\\''/g;
$workingDir =~ s/\"/\\\\\\"/g;
$workingDir =~ s/\\\$/\\\$/g;
$workingDir =~ s/\`/\\\\\\`/g;
$workingDir = "'".$workingDir."'";


my $scriptName = undef;
my $scriptPath = undef;
my $crontabFilePath = "/etc/crontab";
my $mainMenuChoice = undef;
my $choice = undef;
my $confirmationChoice = undef;

my @options = ();
my $numArguments = undef;

#Hash containing the weekdays#
my %hashDays = ( 1 => "MON",
                 2 => "TUE",
                 3 => "WED",
                 4 => "THU",
                 5 => "FRI",
                 6 => "SAT",
                 7 => "SUN"
               );
 
my $hour = undef;
my $minute = undef;

my @linesCrontab = ();
my $entryCrontabString = undef;

my $crontabEntryExists = false;
my $crontabEntry = undef;

if($invokedScript) {
	$mainMenuChoice = $ARGV[0];
}
else {
	checkUser();
	printMainMenu();
	getMainMenuChoice();	
}

loadType();
createDefaultSet();

#If the backup job already exists in crontab#
if(checkEntryExistsCrontab()) {
	$crontabEntryExists = true;
	
	print "\n You have an existing scheduled $jobType Job.";
	
	if($mainMenuChoice == 1 || $mainMenuChoice == 4) {
		print "\n Would you like to create a new one ? (y/n) \n";
	} elsif($mainMenuChoice == 2 || $mainMenuChoice == 5) {
		print "\n Would you like to edit ? (y/n) \n";
		$editFlag = 1;
	} elsif($mainMenuChoice == 3 || $mainMenuChoice == 6) {
		print "\n Would you like to delete ? (y/n) \n";
		$rmFlag = 1;
	}
	else {
	}
	
	if($invokedScript) {
		$confirmationChoice = $ARGV[1];
	} else {
		getConfirmationChoice();
	}
	
	if($confirmationChoice eq "y" || $confirmationChoice eq "Y") {  
		#Remove existing backup job#
		if(!$editFlag) {
			removeEntryFromCrontabLines();
			#<Deepak> writetoCron --> pass content and overwrite
			$scheduleMsg = "\n $jobType Job has been removed successfully. \n\n";
		}
	}
	else {
		exit 0;
	}
}
#Otherwise create a new backup/restore job#
else {
	if($mainMenuChoice == 2 || $mainMenuChoice == 5) {
		print "\n There is no scheduled $jobType Job.";
		print "\n Do you want to add a new one ? (y/n) \n";
		getConfirmationChoice();
		
		if($confirmationChoice eq "y" || $confirmationChoice eq "Y") {
			my $dayOptionPresentCrontab = "";
			my $hourOptionPresentCrontab = "";
			my $minuteOptionPresentCrontab = "";
			
			if($mainMenuChoice == 2) {
				$mainMenuChoice = 1;
			} else {
				$mainMenuChoice = 4;
			}
		}
		else {
			exit 0;
		}
	} 
	elsif($mainMenuChoice == 3 || $mainMenuChoice == 6) {
		print "\n There is no scheduled $jobType Job. \n\n";
		exit 1;
	}
	else {
	}
}

#Create a new backup/restore job /modify an existing backup job #   
if($mainMenuChoice == 1 || $mainMenuChoice == 2 || $mainMenuChoice == 4 || $mainMenuChoice == 5) {
	$crontabEntry =~ s/^\s+//;
	if(defined $crontabEntry) {
		my @optionsPresentCrontab = split / /, $crontabEntry;
		
		$dayOptionPresentCrontab = $optionsPresentCrontab[4];
		$hourOptionPresentCrontab = $optionsPresentCrontab[1];
		$minuteOptionPresentCrontab = $optionsPresentCrontab[0];
		
		my @dayOptionsPresentCrontab = split /,/, $dayOptionPresentCrontab;
		$dayOptionPresentCrontab = undef;
		%reverseHashDays = reverse %hashDays;
		
		for(my $index = 0; $index <= $#dayOptionsPresentCrontab; $index++) {
			$dayOptionsPresentCrontab[$index] = $reverseHashDays{$dayOptionsPresentCrontab[$index]};
		}
		
		$dayOptionPresentCrontab = join ",", @dayOptionsPresentCrontab;
	}
	
	mainOperation();
}

my $writeFlag = writeToCrontab();
if(!$writeFlag) {
	if(!$editFlag && $rmFlag) {
		print "\n Schedule $jobType couldn't be removed.\n\n";
	} else {
		print "\n $jobType couldn't be scheduled\n";
	}
	exit(1);
}
print $scheduleMsg;
system('stty','echo');
exit;

#Subroutine to print Main Menu choice#
sub printMainMenu
{
	system("clear");
	
	print "\n Enter Option \n";
	print " \n";
	print " 1 -> SCHEDULE BACKUP JOB \n";
	print " 2 -> EDIT SCHEDULED BACKUP JOB \n";
	print " 3 -> DELETE SCHEDULED BACKUP JOB \n";
	print " 4 -> SCHEDULE RESTORE JOB \n";
	print " 5 -> EDIT SCHEDULED RESTORE JOB \n";
	print " 6 -> DELETE SCHEDULED RESTORE JOB \n";
	print " \n";
}

#****************************************************************************************************
# Subroutine Name         : checkCronPermission.
# Objective               : Subroutine to check if user has permission to access crontab.
# Added By                : Dhritikana
#*****************************************************************************************************/
sub checkCronPermission {
	if (!-w "/etc/crontab") {
		return 1;
	} 
	return 0;
}

#****************************************************************************************************
# Subroutine Name         : getMainMenuChoice.
# Objective               : Subroutine to get Main Menu choice from user. 
# Added By                : 
#*****************************************************************************************************/
sub getMainMenuChoice
{
  while(!defined $mainMenuChoice)
  {
    print " Enter your choice : ";
    $mainMenuChoice = <>;
    chop $mainMenuChoice;

    $mainMenuChoice =~ s/^\s+//;
    $mainMenuChoice =~ s/\s+$//;

    if($mainMenuChoice =~ m/^\d$/)
    {
      if($mainMenuChoice < 1 || $mainMenuChoice > 6)
      {
        $mainMenuChoice = undef;
        print " Invalid choice : ";
      } 
    }
    else
    {
      $mainMenuChoice = undef;
      print " Invalid choice : ";
    }
  }
}

#****************************************************************************************************
# Subroutine Name         : getChoiceofDayWk.
# Objective               : Subroutine to get Main Menu choice from user. 
# Added By                : 
#*****************************************************************************************************/
sub getChoiceofDayWk {
	while(!defined $dayWkOp) {
		print " Enter your choice : ";
		$dayWkOp = <>;
		chop $dayWkOp;
		
		$dayWkOp =~ s/^\s+//;
		$dayWkOp =~ s/\s+$//;
		
		if($dayWkOp =~ m/^\d$/) {
			if($dayWkOp < 1 || $dayWkOp > 2) {
				$dayWkOp = undef;
				print " Invalid choice : ";
			} 
		}
		else {
			$dayWkOp = undef;
			print " Invalid choice : ";
		}
	}
}

#****************************************************************************************************
# Subroutine Name         : getConfirmationChoice.
# Objective               : Subroutine to get confirmation choice from user. 
# Added By                : 
#*****************************************************************************************************/
sub getConfirmationChoice {
  while(!defined $confirmationChoice) {
    print " Enter your choice : ";
    $confirmationChoice = <>;
    chop $confirmationChoice;

    $confirmationChoice =~ s/^\s+//;
    $confirmationChoice =~ s/\s+$//;

    if($confirmationChoice =~ m/^\w$/ && $confirmationChoice !~ m/^\d$/) {
      if($confirmationChoice eq "y" ||
         $confirmationChoice eq "Y" ||
         $confirmationChoice eq "n" ||
         $confirmationChoice eq "N")
      {
      }
      else
      {
        $confirmationChoice = undef;
        print " Invalid choice : ";
      } 
    }
    else
    {
      $confirmationChoice = undef;
      print " Invalid choice : ";
    }
  }
  
  print "\n";
}

#****************************************************************************************************
# Subroutine Name         : loadType.
# Objective               : Subrouting to load jobType (Backup/Restore) based on User Choice. 
# Added By                : Dhritikana
#*****************************************************************************************************/
sub loadType {
        if($mainMenuChoice <=3 && $mainMenuChoice >=1) {
                $jobType = "Backup";
                $scriptType = "Backup_Script.pl";
        } elsif($mainMenuChoice <=6 && $mainMenuChoice >=4) {
                $jobType = "Restore";
                $scriptType = "Restore_Script.pl";
        }
        #$JobPath = "$usrProfilePath/$userName/$jobType/Scheduled/";
		#$JobPath =~ s/\'/\'\\''/g;
		#$JobPath =~ s/\"/\\\\\\"/g;
		#$JobPath =~ s/\\\$/\\\$/g;
		#$JobPath =~ s/\`/\\\\\\`/g;
		#$JobPath = "'".$JobPath."'";
		$jobRunningDir = "$usrProfilePath/$userName/$jobType/Scheduled";
		if(!-e $jobRunningDir) {
			my $ret = mkdir($jobRunningDir);
				if($ret ne 1) {
					print CONST->{'MkDirErr'}.$jobRunningDir.": $!".$lineFeed;
					exit 1;
			}
		}
		chmod 0777, $jobRunningDir;
		
        $scriptName = "perl $scriptType";
        $scriptPath = "cd ".$workingDir."; ".$scriptName." $jobType $userName";
}

#****************************************************************************************************
# Subroutine Name         : printChoiceOfDayWk.
# Objective               : Subroutine to print the menu of daily or weekly choices 
# Added By                : Dhritikana
#*****************************************************************************************************/
sub printChoiceOfDayWk
{
	system("clear");
	
	print "\n Enter your choice to run Schedule $jobType Job \n";
	print " 1 -> DAILY \n";
	print " 2 -> WEEKLY \n";
	print " \n";
}


#****************************************************************************************************
# Subroutine Name         : printAddCrontabMenu.
# Objective               : Subroutine to print the menu for adding an entry to crontab. 
# Added By                : 
#*****************************************************************************************************/
sub printAddCrontabMenu
{
	system("clear");
	
	print "\n Enter the Day(s) of Week for the Scheduled $jobType Job \n";
	print " Note: Use comma separation for selecting multiple days (E.g. 1,3,5) \n";
	print " \n";
	print " 1 -> MON \n";
	print " 2 -> TUE \n";
	print " 3 -> WED \n";
	print " 4 -> THU \n";
	print " 5 -> FRI \n";
	print " 6 -> SAT \n";
	print " 7 -> SUN \n";
	print " \n";
}

#****************************************************************************************************
# Subroutine Name         : getDays.
# Objective               : Subroutine to get the days of week when the backup job should be executed. 
# Added By                : 
#*****************************************************************************************************/
sub getDays
{
	if(${$_[0]} ne "") {
		print " Previous choice : ${$_[0]} \n";
	}
	
	while(!defined $choice) {
		print " Enter your choice : ";
		
		$choice = <>;
		chop $choice;
		
		$choice =~ s/^\s+//;
		$choice =~ s/\s+$//;
		
		if($choice =~ m/^(\d,)*\d$/) {
		  @options = split /,/, $choice;
		  $numArguments = $#options + 1;
		
		  if($numArguments > 7) {
			$choice = undef;
			@options = ();
			print " Invalid choice : ";
		  }
		  else {
			my $duplicateExists = checkDuplicatesArray(\@options);
		
			if($duplicateExists) {
			  $choice = undef;
			  @options = ();
			  print " Invalid choice : ";
			}
			else {
			  my $entry;
		
			  foreach $entry (@options) {
				if($entry < 1 || $entry > 7) {
				  $choice = undef;
				  @optionsoptions = ();
				  print " Invalid choice : ";
				  last;
				}
			  } 
			}
		  } 
		}
		else {
		  $choice = undef;
		  print " Invalid choice : ";
		}
	}
}

#****************************************************************************************************
# Subroutine Name         : getHour.
# Objective               : Subroutine to get the hour when the backup/restore job should be executed. 
# Added By                : 
#*****************************************************************************************************/
sub getHour
{
	if(!$selectJobTermination) {
		print "\n Enter Time of the Day when $jobType is supposed to run \n\n";
	}
	
	if(${$_[0]} ne "") {
		print " Previously entered Hour : ${$_[0]} \n";
	} 
	
	my $Choosenhour = undef;
	while(!defined $Choosenhour) { 
		print " Enter Hour (0-23) : ";
		
		$Choosenhour = <>;
		chop $Choosenhour;
		
		$Choosenhour =~ s/^\s+//;
		$Choosenhour =~ s/\s+$//;
		
		if($Choosenhour eq "" or $Choosenhour =~ m/\D/ or $Choosenhour < 0 or $Choosenhour > 23) {
			$Choosenhour = undef;
			print " Invalid choice : ";
		}
		else {
			if(length $Choosenhour > 1 && $Choosenhour =~ m/^0/) {
				$Choosenhour = substr $Choosenhour, 1;  
			}
		return $Choosenhour;
		}
	}
}

#****************************************************************************************************
# Subroutine Name         : getMinute.
# Objective               : Subroutine to get the minute when the backup job should be executed. 
# Added By                : 
#*****************************************************************************************************/
sub getMinute
{
	print "\n";
	
	if(${$_[0]} ne "") {
		print " Previously entered Minute : ${$_[0]} \n";
	}
		my $ChoosenMinute = undef;
		while(!defined $ChoosenMinute) { 
			print " Enter Minute (0-59) : ";
			$ChoosenMinute = <>;
			chop $ChoosenMinute;
			
			$ChoosenMinute =~ s/^\s+//;
			$ChoosenMinute =~ s/\s+$//;
			
			if($ChoosenMinute eq "" or $ChoosenMinute =~ m/\D/ or $ChoosenMinute < 0 or $ChoosenMinute > 59){
				$ChoosenMinute = undef;
				print " Invalid choice : ";
			}
			else {
				if(length $ChoosenMinute == 1) {
				$ChoosenMinute = "0".$ChoosenMinute;  
				}
			return $ChoosenMinute;
			}
	}
	print "\n";
}

#****************************************************************************************************
# Subroutine Name         : getNscheduleCutOff.
# Objective               : Subroutine to get Cut Off Time from user and write to it crontab. 
# Added By                : Dhritikana Kalita
#*****************************************************************************************************/
sub getNscheduleCutOff {
	print "\n";
	print " Do you want to have a cut off time for $jobType(y/n)?\n";
	$confirmationChoice = undef;
	getConfirmationChoice();
	if($confirmationChoice eq "y" || $confirmationChoice eq "Y") {  
		$selectJobTermination = 1;
		$terminateHour = getHour();
		$terminateMinute = getMinute();	
		
		while(1) {
			my $cutoffDiff = undef;
			if($hour eq $terminateHour) {
				$cutoffDiff = $terminateMinute-$minute;
			} elsif($terminateHour-$hour == 1 && $minute > 55) {
				$cutoffDiff = 60+$terminateMinute-$minute;
			} elsif($hour == 23 && $terminateHour == 0 && $minute > 55) {
				$cutoffDiff = 60+$terminateMinute-$minute;
			} else {
				last;
			}
			
			if($cutoffDiff >= 0 && $cutoffDiff < 5) {
				print $whiteSpace.CONST->{'WrongCutOff'}.$lineFeed.$lineFeed;
				$terminateHour = getHour();
				$terminateMinute = getMinute();
			} else {
				last;
			}
		}
	    $scriptName = "perl Job_Termination_Script.pl";
		$scriptPath = "cd ".$workingDir."; ".$scriptName." $jobType $userName";
	}
}

#****************************************************************************************************
# Subroutine Name         : mainOperation.
# Objective               : Subroutine to get Cut Off Time from user. 
# Added By                : Dhritikana Kalita
#*****************************************************************************************************/
sub mainOperation {
	printChoiceOfDayWk();
	getChoiceofDayWk();
	if($dayWkOp eq 2) {
		printAddCrontabMenu();
		getDays(\$dayOptionPresentCrontab);
	} else {
		$choice = "1,2,3,4,5,6,7";
		@options = split (/\,/, $choice);
		$numArguments = $#options + 1;
	}
	
	$hour = getHour(\$hourOptionPresentCrontab);
	$minute = getMinute(\$minuteOptionPresentCrontab);
	
	if($editFlag) {
		removeEntryFromCrontabLines();
	}
	$entryCrontabString = createCrontabEntry(\$scriptPath, \$minute, \$hour);
	push(@linesCrontab, $entryCrontabString);

	my @daysEntered = split /,/, $choice;
	
	if($mainMenuChoice == 1 || $mainMenuChoice == 4) {
		$scheduleMsg = "\n $jobType Job has been scheduled successfully on";
	
		foreach my $value (@daysEntered) {
			$scheduleMsg .= " $hashDays{$value}";
		}
		$scheduleMsg .= " at $hour:$minute. \n\n";
	}
	elsif($mainMenuChoice == 2 || $mainMenuChoice == 5) { 
		my @daysEnteredCrontab = split /,/, $dayOptionPresentCrontab;
		
		$scheduleMsg .= "\n $jobType Job has been modified successfully from";
		
		foreach my $value (@daysEnteredCrontab) {
			$scheduleMsg .= " $hashDays{$value}";
		}
		
		$scheduleMsg .= " at $hourOptionPresentCrontab:$minuteOptionPresentCrontab to";
		
		foreach my $value (@daysEntered) {
			$scheduleMsg .= " $hashDays{$value}";
		}
		$scheduleMsg .= " at $hour:$minute. \n\n";
	}
	else {
	}
	
	getNscheduleCutOff();
	if(!$selectJobTermination) {
		return;
	}
	
	$entryCrontabString = createCrontabEntry(\$scriptPath, \$terminateMinute, \$terminateHour);
	push(@linesCrontab, $entryCrontabString);
	
	$scheduleMsg .= " Cut off for $jobType has been scheduled successfully on";
	foreach my $value (@daysEntered) {
		if($terminateHour < $hour) {
			if( $value < 7 ) {
				$value = $value+1;
			} elsif($value == 7) {
				$value = 1;
			}
		}
		$scheduleMsg .= " $hashDays{$value}";
	}
	$scheduleMsg .= " at $terminateHour:$terminateMinute. \n\n";
}

#****************************************************************************************************
# Subroutine Name         : checkDuplicatesArray.
# Objective               : Subroutine to check if the same day has been entered more than once by the user. 
# Added By                : 
#*****************************************************************************************************/
sub checkDuplicatesArray
{
	my $retVal = false;
	my @originalArray = @{$_[0]};  
	my %optionsHash = ();
	
	foreach $var (@originalArray) {
		if(exists $optionsHash{$var}) {
			$optionsHash{$var}++;
		}
		else {
			$optionsHash{$var} = 1;
		}
	}  
	
	while(($key,$value) = each(%optionsHash)) {
		if($value > 1) {
			$retVal = true;
			last;
		}
	}
	
	return $retVal;
}

#****************************************************************************************************
# Subroutine Name         : createCrontabEntry.
# Objective               : Subroutine to create the string to be entered into crontab. 
# Added By                : 
#*****************************************************************************************************/
sub createCrontabEntry
{
	my $scriptPath = ${$_[0]};
	my $entryCrontabString  = ${$_[1]};
	$entryCrontabString .= " ";
	$entryCrontabString .= ${$_[2]};
	$entryCrontabString .= " ";
	$entryCrontabString .= "*";
	$entryCrontabString .= " ";
	$entryCrontabString .= "*";
	$entryCrontabString .= " ";
	
	if($numArguments == 1) {
		$entryCrontabString .= $hashDays{$options[$numArguments - 1]};
	}
	else {
		for(my $index=0; $index<$numArguments - 1; $index++) {
			$entryCrontabString .= $hashDays{$options[$index]};
			$entryCrontabString .= ",";
		}
		
		$entryCrontabString .= $hashDays{$options[$numArguments - 1]};
	}  
	
	$entryCrontabString .= " ";
	$entryCrontabString .= $user;
	
	$entryCrontabString .= " ";
	$entryCrontabString .= $scriptPath;
	
	$entryCrontabString .= "\n";
	return $entryCrontabString;
}

#****************************************************************************************************
# Subroutine Name         : checkEntryExistsCrontab.
# Objective               : Subroutine to check if crontab has an existing backup job corresponding to 
#							the backup script. 
# Added By                : 
#*****************************************************************************************************/
sub checkEntryExistsCrontab()
{
  readFromCrontab();

  foreach my $line (@linesCrontab)
  {
    #if($line =~ m/$scriptName/)
    if($line =~ m/$scriptPath/)
    {
      $crontabEntry = $line;
      return true;
    }
  }
  return false;
}

#****************************************************************************************************
# Subroutine Name		: removeEntryFromCrontabLines.
# Objective				: Subroutine to remove an existing backup job from crontab corresponding
#							to the backup script. 
# Modified By			: Dhritikana
#*****************************************************************************************************/
sub removeEntryFromCrontabLines
{
	my $jobExists = "$scriptName $jobType $userName";
	my $cutOffExist = "perl Job_Termination_Script.pl $jobType $userName";
	
	@linesCrontab = grep !/$jobExists/, @linesCrontab;
	@linesCrontab = grep !/$cutOffExist/, @linesCrontab;
}

#****************************************************************************************************
# Subroutine Name         : readFromCrontab.
# Objective               : Read entire crontab file.
# Added By                : 
#*****************************************************************************************************/
sub readFromCrontab
{
	open CRONTABFILE, "<", $crontabFilePath or (print "$lineFeed Couldn't open file $crontabFilePath. :$! $lineFeed" and die);
	@linesCrontab = <CRONTABFILE>;  
	close CRONTABFILE;
}

#****************************************************************************************************
# Subroutine Name		: writeToCrontab.
# Objective				: Append an entry to crontab file.
# Modified By			: Dhritikana
#*****************************************************************************************************/
sub writeToCrontab
{
	my $command = undef;
	s/^\s+// for @linesCrontab;
	my $temp = "$jobRunningDir/operationsfile.txt";
	if(!open TEMP, ">", $temp) {
		print $tHandle "$!\n";
		print "unable $!";
		exit;
	}
	print TEMP "Schedule\n";
	print TEMP @linesCrontab;
	close TEMP;
	chmod 0777, $temp;
	
	if($noRoot) {
		print CONST->{'CronQuery'};
		$command = "su -c \"perl operations.pl $jobRunningDir\" root";
	} else {
		$command = "perl operations.pl $jobRunningDir";
	}
	
	message(" Cron entry command: $command");
	
	my $res = system($command);
	unlink($temp);
	if($res ne "0") {
		return 0;
	}
	return 1;
}

#****************************************************************************************************
# Subroutine Name         : checkUser.
# Objective               : This function will check user and if not root will prompt for credentials.
# Added By                : Dhritikana
#*****************************************************************************************************/
sub checkUser {
	system("clear");
	
	my $checkUserCmd = "whoami";
	$user = `$checkUserCmd`;
	chomp($user);
	if($user ne "root") {
		$noRoot = 1;
	}
}

#****************************************************************************
# Subroutine Name         : cancelProcess
# Objective               : Cleanup if user cancel.
# Added By                : Dhritikana
#****************************************************************************/
sub cancelProcess {
	system('stty','echo');
}

#****************************************************************************
# Subroutine Name         : createDefaultSet
# Objective               : Creating Default set for Backup/Restore job.
# Added By                : Dhritikana
#****************************************************************************/
sub createDefaultSet {	
	$DefaultSet = $usrProfilePath."/".$userName."/Default$jobType"."set";
	
	if($jobType eq "Backup") {
		$currentJobFileset = $backupsetFilePathfromConf;
	} elsif($jobType eq "Restore") {
		$currentJobFileset = $RestoresetFile;
	}
	
	if(!-e $currentJobFileset) {
		print "Your $jobType file doesn't exist in current directory. Please create and try again.\n";
		exit(1);
	}
	
	if(!-s $currentJobFileset) {
		print "Your $jobType file set is empty. Please fill and retry.\n";
		exit(1);
	}
	
	my $flag = copy($currentJobFileset,$DefaultSet);
	if(!$flag) {
		print "\n Couldn't create Default $jobType set: $DefaultSet from $currentJobFileset, Reason: $!\n";
		exit(1);
	}
	chmod 0777, $DefaultSet;
}
