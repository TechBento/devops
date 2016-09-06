require "header.pl";
use Constants 'CONST';

use constant CHILD_PROCESS_STARTED => 1;
use constant CHILD_PROCESS_COMPLETED => 2;
use constant LIMIT => 2*1024;

my $operationComplete = "100%";
my $lineCount;
my $prevLineCount;
	
use constant false => 0;
use constant true => 1;
use constant RELATIVE => "--relative";
use constant NORELATIVE => "--no-relative";

use constant false => 0;
use constant true => 1;

my $curFile = basename(__FILE__);   
print $tHandle "File: $curFile $lineFeed ---------------------------------------- $lineFeed";

my @linestemp_file;
my @linesCrontabConfigFile; 
my $cronData = "";					   
my $isLocalBackup = undef;
my $flagToCheckSchdule = undef;
my $failedfiles_index = 0;
my %fileSetHash = undef;
my $fileBackupCount = 0;
my $fileRestoreCount = 0;
my $fileSyncCount = 0;
my $failedfiles_count = 0;
my $exit_flag = 0;
my $retryAttempt = false; # flag to indicate the backup script to retry the backup/restore
my @currentFileset;
my $totalSize = CONST->{'CalCulate'};
my $parseCount = 0;


my $Oflag = 0;
my $pflag = 0;
my $fieldSeparator = "\\] \\[";
my $skipFlag = 0;
my $fileNotOpened = 0;
my $buffer = "";
my $byteRead = 0;
my $lastLine  = "";
my $termData = "CHILD_PROCESS_COMPLETED";
my $prevLine = undef;
my $IncFileSize = undef;
my $sizeofSIZE = undef;
my $prevFile = undef;
my $tryCount = 0;
my $progressHeader = 0;

# parameters sent with the script calling
$jobRunningDir = $ARGV[0];
$outputFilePath = $ARGV[1];						   
$curFileset = $ARGV[2];
$relative = $ARGV[3];
$current_source = $ARGV[4];

my $temp_file = "$jobRunningDir/operationsfile.txt"; 
my $pidPath = "$jobRunningDir/pid.txt";
my $evsTempDirPath = "$evsTempDir/evs_temp";
$statusFilePath = "$jobRunningDir/STATUS_FILE";
my $retryinfo = "$jobRunningDir/".$retryinfo;
my $progressDetailsFilePath = undef;
$idevsOutputFile = "$jobRunningDir/output.txt";
$idevsErrorFile = "$jobRunningDir/error.txt";
my $fileForSize = "$jobRunningDir/TotalSizeFile";

# Index number for statusFileArray
use constant COUNT_FILES_INDEX => 0;
use constant SYNC_COUNT_FILES_INDEX => 1;
use constant ERROR_COUNT_FILES => 2;
use constant FAILEDFILES_LISTIDX => 3;
use constant EXIT_FLAG_INDEX => 4;
use constant PROGRESS_HEADER => 5;



# Status File Parameters
my @statusFileArray = 	( 	"COUNT_FILES_INDEX",
							"SYNC_COUNT_FILES_INDEX",
							"ERROR_COUNT_FILES",
							"FAILEDFILES_LISTIDX",
							"EXIT_FLAG",
							"PROGRESS_HEADER",
						);
						
# signal handlers
$SIG{INT} = \&process_term;
$SIG{TERM} = \&process_term;
$SIG{TSTP} = \&process_term;
$SIG{QUIT} = \&process_term;
$SIG{USR1} = \&process_term;

operations();

#****************************************************************************************************
# Subroutine Name         : operations
# Objective               : Makes call to the respective function depending on operation
# Added By                : 
#*****************************************************************************************************/
sub operations
{
	if(!open(TEMP_FILE, "<",$temp_file)){
		$errStr = "Could not open file temp_file in Child process: $temp_file, Reason:$!";
		print $tHandle $errStr."\n";
		return 0;
	}
	@linestemp_file = <TEMP_FILE>;
	close TEMP_FILE;

	chomp($linestemp_file[0]);
	
	if($linestemp_file[0] eq 'Schedule') {
		writeToCrontab();
		exit;
	}
	
	my $a = rindex ($curFileset, '/');
	my $error_file = substr($curFileset,$a+1)."_ERROR";
	$currentErrorFile = $jobRunningDir."/ERROR/".$error_file;
	
	open FILESET, "< $curFileset" or print $tHandle "Couldn't open file $curFileset $!.$lineFeed" and return;
	if($curFileset =~ /versionRestore/) {
		my $param = <FILESET>;
		my $idx = rindex($param, "_");
		$param = substr($param, 0, $idx);
		$fileSetHash{$param} = 0;
		push @currentFileset, $param;
	} else {
		while(<FILESET>) {
			chomp($_);
			$fileSetHash{$_} = 0;
			push @currentFileset, $_;
		}
	}
	close FILESET;
	
	if($jobRunningDir =~ /Scheduled/) {
		$flagToCheckSchdule = 1;   
	}
	
	if($linestemp_file[0] eq 'BackupOutputParse') {
		$jobType = "BACKUP";
		$progressDetailsFilePath = "$usrProfileDir/PROGRESS_DETAILS_".$jobType;
		# Trace Log entry
		print $tHandle "BackupOutputParse: $lineFeed------------------------------- $lineFeed";
		BackupOutputParse();
		subErrorRoutine(); 
		writeParameterValuesToStatusFile();
	}
	elsif($linestemp_file[0] eq 'RestoreOutputParse') {
		$jobType = "RESTORE";
		$progressDetailsFilePath = "$usrProfileDir/PROGRESS_DETAILS_".$jobType;
		RestoreOutputParse();	
		subErrorRoutine(); 
		writeParameterValuesToStatusFile();
	} 
	else {
		print $tHandle "\n function not in this file\n";
		return 0;
	}
	unlink $temp_file;
}

#****************************************************************************************************
# Subroutine Name         : BackupOutputParse.
# Objective               : This function monitors and parse the evs output file and creates the App 
#							log file which is shown to user. 					
# Modified By             : Deepak Chaurasia
#*****************************************************************************************************/
sub BackupOutputParse()
{
	my $fields_in_progress = 10;

	if(open(OUTFILE, ">> $outputFilePath")){
		chmod 0777, $outputFilePath;
	}
	else {
		$Oflag = 1;
		print $tHandle CONST->{'FileOpnErr'}.$whiteSpace."\$outputFilePath: ".$outputFilePath." Reason:$! $lineFeed";
		print CONST->{'FileOpnErr'}.$whiteSpace."\$outputFilePath: ".$outputFilePath." Reason:$! $lineFeed";
		return 0;
	}

	$progressHeader = getParameterValueFromStatusFile('PROGRESS_HEADER');

	if(!$flagToCheckSchdule && $progressHeader != 1) {
		my $header = "---------------------------------------------------------------------------------\n".
				"                       BACKUP PROGRESS                        \n".
				"---------------------------------------------------------------------------------\n".
				"FILE NAME | FILE SIZE | BACKUPSET SIZE | TRANSFER RATE | PERCENTAGE | PROGRESS \n".
				"---------------------------------------------------------------------------------\n";
		print $header;
		$statusHash{'PROGRESS_HEADER'} = 1;
		putParameterValueInStatusFile();
	} else {
		if(!open(PROGRESSFILE, ">", $progressDetailsFilePath)) {
			$pflag = 1;
			print $tHandle CONST->{'FileOpnErr'}.$whiteSpace."\$progressDetailsFilePath: ".$progressDetailsFilePath." Reason:$! $lineFeed";
			print CONST->{'FileOpnErr'}.$whiteSpace."\$progressDetailsFilePath ".$progressDetailsFilePath." Reason:$! $lineFeed";
		}
		chmod 0777, $progressDetailsFilePath;
	}

	while(!$fileNotOpened) {
		if(!-e $pidPath){
				last;
		}
		if(-e $idevsOutputFile) {
			chmod 0777, $idevsOutputFile;
			open TEMPOUTPUTFILE, "<", $idevsOutputFile and $fileNotOpened = 1;
		}
		else{
			sleep(2);
		}
	}
	
	while (1) {	
		$byteRead = read(TEMPOUTPUTFILE, $buffer, LIMIT);
		if($byteRead == 0) {
			if(!-e $pidPath){
				last;
			}
			sleep(2);
			seek(TEMPOUTPUTFILE, 0, 1);		#to clear eof flag
			next;
		}
		
		$tryCount = 0;
		
		if("" ne $lastLine)	{		# need to check appending partial record to packet or to first line of packet
			$buffer = $lastLine . $buffer;
		}
		
		my @resultList = split /\n/, $buffer;
		my $bufIndex = @resultList;
		
		if($buffer !~ /\n$/) {      #keep last line of buffer only when it not ends with newline.
			$lastLine = $resultList[$#resultList];
			$bufIndex -= 1;
		}
		else {
			$lastLine = "";
		}
		
		for(my $cnt = 0; $cnt < $bufIndex; $cnt++) {
			
			my $tmpLine = $resultList[$cnt];
			my @fields = split("\\] \\[",$tmpLine, $fields_in_progress);
			my $total_fields = @fields;
			
			if($total_fields == $fields_in_progress) {
				$fields[0] =~ s/^.//; # remove starting character [ from first field
				$fields[$fields_in_progress-1] =~ s/.$//; # remove last character ] from last field
				#chop($fields[$fields_in_progress-1]);
				
				# remove spaces from beginning from required fields
				$fields[0] =~ s/^\s+//;
				$fields[$fields_in_progress-2] =~ s/^\s+//;
				
				my $keyString = "$pathSeparator$fields[$fields_in_progress-1]";
				
				my $backupFinishTime = localtime;
				my $fileSize = convertFileSize($fields[0]); 
				my $pKeyString = $keyString;
				if($tmpLine =~ m/$operationComplete/) {
					if($fields[$fields_in_progress-2] eq "FILE IN SYNC") { 		# check if file in sync
						$fileSyncCount++;
						if(defined($fileSetHash{$keyString})) {
							$fileSetHash{$keyString} = 1;
						} else {
							$fullPath = getFullPathofFile($keyString);
						}	
					}
					elsif($fields[$fields_in_progress-2] eq "FULL" or $fields[$fields_in_progress-2] eq "INCREMENTAL") {  	# check if file is backing up as full or incremental
						$fileBackupCount++;
						if(defined($fileSetHash{$keyString})) {
							$fileSetHash{$keyString} = 1;
						} else {
							$fullPath = getFullPathofFile($keyString);
						}
						if($relative eq NORELATIVE) {
							my $indx = rindex ($pKeyString, '/');
							$pKeyString = substr($pKeyString, $indx);
						}
						#print OUTFILE "[$backupFinishTime] [$fields[$fields_in_progress-2] Backup] [SUCCESS] [$pathSeparator$fields[$fields_in_progress-1]][$fileSize]".$lineFeed;
						print OUTFILE "[$backupFinishTime] [$fields[$fields_in_progress-2] Backup] [SUCCESS] [$pKeyString][$fileSize]".$lineFeed;
					}
					else{
						addtionalErrorInfo(\$currentErrorFile, \$tmpLine);
					}
					$parseCount++;
				} 
				
				if($tmpLine ne $prevLine) {
						$lineFeedPrinted = false;
						#if($prevFile ne $keyString) {
						#	$IncFileSizeByte += $fields[0];
						#}
				}
			
				if($cnt%10 == 0 and $totalSize eq CONST->{'CalCulate'}) {
					if(open(FILESIZE, "<$fileForSize")) {
						$totalSize = <FILESIZE>;
						close(FILESIZE);
						chomp($totalSize);
						if($totalSize eq "") {
							$totalSize = CONST->{'CalCulate'};
						}
					}
				}
						
				if($flagToCheckSchdule && !$pflag) {
					$progress = $pKeyString.$whiteSpace.$fields[$fields_in_progress-5].$whiteSpace.$fields[0].$whiteSpace.$totalSize.$whiteSpace.$fields[$fields_in_progress-4];
					seek(PROGRESSFILE, 0, 0);
					print PROGRESSFILE $progress; 
				} elsif(!$flagToCheckSchdule) {
					displayProgressBar($pKeyString, $fields[$fields_in_progress-5], $fields[0], $totalSize, $fields[$fields_in_progress-4]);
				}
				$prevLine = $tmpLine;
				$prevFile = $keyString;
			}
			
			if($tmpLine =~ /$termData/ ) {
				close TEMPOUTPUTFILE;				
				$skipFlag = 1;
			} 
			
			if($tmpLine !~ m/building file list/ and 
			$tmpLine !~ m/=============/ and 
			$tmpLine !~ m/connection established/ and 
			$tmpLine !~ m/bytes  received/ and 
			$tmpLine !~ m/\| FILE SIZE \| TRANSFERED SIZE \| TOTAL SIZE \|/ and
			$tmpLine !~ m/\%\]\s+\[/ and
			$tmpLine !~ m/$termData/) {
				if($tmpLine ne ''){
					$errStr = $tmpLine;
					addtionalErrorInfo(\$currentErrorFile, \$tmpLine);
				}
			}
		}
		
		if($skipFlag) {
			#if($flagToCheckSchdule) {
			#	my $end = "FileName=END_OF_PROCESS".$whiteSpace."PercentComplete=100".$lineFeed;
			#	seek(PROGRESSFILE, 0, 0);
			#	print PROGRESSFILE $end; 
			#}
			last;
		}
	}
	
	if(!$Oflag) {
		close OUTFILE;
	}
	
	if(!$pflag) {
		close PROGRESSFILE;
	}
}

#****************************************************************************************************
# Subroutine Name         : subErrorRoutine.
# Objective               : This function monitors and parse the evs output file and creates the App 
#							log file which is shown to user. 					
# Modified By             : Deepak Chaurasia
# Modified By			  : Dhritikana
#*****************************************************************************************************/
sub subErrorRoutine()
{
	$failedfiles_count = getFailedFileCount();
	my $individual_errorfile = "$currentErrorFile";
	copyTempErrorFile($individual_errorfile);
	
	#Check if retry is required
	#getParameterValueFromStatusFile(\$statusFileArray[FAILEDFILES_LISTIDX],\$failedfiles_index);
	$failedfiles_index = getParameterValueFromStatusFile('FAILEDFILES_LISTIDX');
	
	if($failedfiles_count > 0 and $failedfiles_index != -1) { 
		if(!checkretryAttempt($individual_errorfile)){ 
			updateFailedFileCount();
			getFinalErrorFile();
			return;
		}
	} 
	else {
		updateFailedFileCount();
		getFinalErrorFile();
		return;
	}
	
	if(!$retryAttempt or $failedfiles_index == -1) {
		getFinalErrorFile();
	} else {
		$failedfiles_index++;
		$failedfiles = $jobRunningDir."/".$failedFileName.$failedfiles_index; 
		my $oldfile_error = $currentErrorFile;
		my $newfile_error = $jobRunningDir."/ERROR/$failedFileName.$failedfiles_index"."_ERROR";
		
		if(-e $oldfile_error or -e $currentErrorFile."_FINAL") {
			rename $oldfile_error, $newfile_error;
		}
		if(!open(FAILEDLIST, "> $failedfiles")) {
			print $tHandle "Could not open file failedfiles in SubErrorRoutine: $failedfiles, Reason:$!".$lineFeed;
			updateFailedFileCount();
			return;
		}
		chmod 0777, $failedfiles;

		for(my $i = 0; $i <= $#failedfiles_array; $i++) {
			print FAILEDLIST "$failedfiles_array[$i]\n";
		}
		close FAILEDLIST;
		
		if(-e $failedfiles){
			open RETRYINFO, ">> $retryinfo";
			print RETRYINFO "$failedfiles $relative $current_source\n";
			close RETRYINFO;
			chmod 0777, $retryinfo;
		}
	}

	updateFailedFileCount();
}

#****************************************************************************************************************************
# Subroutine Name         : getFailedFileCount
# Objective               : This subroutine gets the failed files count from the failedfiles array  
# Modified By             : Pooja Havaldar
#******************************************************************************************************************************/
sub getFailedFileCount()
{
	my $failed_count = 0;
	for(my $i = 0; $i <= $#currentFileset; $i++){
		chomp $currentFileset[$i];
		if($fileSetHash{$currentFileset[$i]} == 0){
			$failedfiles_array[$failed_count] = $currentFileset[$i];
			$failed_count++;
		}
	}
	return $failed_count;
}

#****************************************************************************************************
# Subroutine Name         : getFullPathofFile.
# Objective               :         
# Added By				  : Pooja Havaldar
#*****************************************************************************************************/
sub getFullPathofFile
{
	$fileToCheck = $_[0];
	for(my $i = $#currentFileset ; $i >= 0; $i--){
		$a = rindex ($currentFileset[$i], '/');
		$match = substr($currentFileset[$i],$a);
		#print $tHandle "\n match = $match ";
		
		if($fileToCheck eq $match){
			$fileSetHash{$currentFileset[$i]} = 1;
			#print $tHandle "\nin getFullPath func \nkey - fileSetHash{$currentFileset[$i]}\n value - $fileSetHash{$currentFileset[$i]} \n";
			last;
		}
	}
}

#****************************************************************************************************************************
# Subroutine Name         : updateFailedFileCount
# Objective               : This subroutine gets the updated failed files count incase retry backup is in process  
# Modified By             : Pooja Havaldar
#******************************************************************************************************************************/
sub updateFailedFileCount()
{
	$orig_count = getParameterValueFromStatusFile('ERROR_COUNT_FILES');
	if($curFileset =~ m/failedfiles.txt/) {
		$size_Backupset = $#currentFileset+1;
		$newcount = $orig_count - $size_Backupset + $failedfiles_count;
		#print $tHandle "\n updateFailedFileCount function - orig_count = $orig_count \n size_Backupset = $size_Backupset\n failedfiles_count = $failedfiles_count\n newcount = $newcount";
		$failedfiles_count = $newcount;
	} else {
		$orig_count += $failedfiles_count;
		$failedfiles_count = $orig_count;
	}
}

#****************************************************************************************************
# Subroutine Name         : checkretryAttempt.
# Objective               : This function checks whether backup has to retry              
# Added By				  : Pooja Havaldar
#*****************************************************************************************************/
sub checkretryAttempt
{
	my $errorline = "idevs error";
	my $individual_errorfile = $_[0];
	
	if(!-e $individual_errorfile) {
		return 0;
	}
	#check for retry attempt
	if(!open(TEMPERRORFILE, "< $individual_errorfile")) {
		print $tHandle "Could not open file individual_errorfile in checkretryAttempt: $individual_errorfile, Reason:$! $lineFeed";
		return 0;
	}
	
	@linesBackupErrorFile = <TEMPERRORFILE>;
	close TEMPERRORFILE;

	chomp(@linesBackupErrorFile);
	for(my $i = 0; $i<= $#linesBackupErrorFile; $i++) {
		$linesBackupErrorFile[$i] =~ s/^\s+|\s+$//g;
		
		print $tHandle "\n linesBackupErrorFile[$i] = *$linesBackupErrorFile[$i]*\n";
		if($linesBackupErrorFile[$i] eq "" or $linesBackupErrorFile[$i] =~ m/$errorline/){
			next;
		}
		
		for(my $j=0; $j<=$#ErrorArgumentsExit; $j++)
		{
			if($linesBackupErrorFile[$i] =~ m/$ErrorArgumentsExit[$j]/)
			{
				$errStr = "Operation could not be completed. Reason : $ErrorArgumentsExit[$j]. $lineFeed";
				print $tHandle $errStr;
				rmtree($evsTempDirPath);
				#kill evs and then exit
				my $jobTerminationPath = $currentDir."/Job_Termination_Script.pl"; 
				system("perl \'$jobTerminationPath\' \'retryExit\' \'$userName\' \'$jobRunningDir\' 1>/dev/nul 2>/dev/nul");
				$exit_flag = "1-$errStr";
				return 0;
			}
		}	
	}
	
	chomp(@linesBackupErrorFile);
	for(my $i = 0; $i<= $#linesBackupErrorFile; $i++) {
		$linesBackupErrorFile[$i] =~ s/^\s+|\s+$//g;
		
		#print $tHandle "\n linesBackupErrorFile = *$linesBackupErrorFile[$i]*\n";
		if($linesBackupErrorFile[$i] eq "" or $linesBackupErrorFile[$i] =~ m/$errorline/){
			next;
		}
		
		for(my $j=0; $j<=$#ErrorArgumentsRetry; $j++)
		{
			if($linesBackupErrorFile[$i] =~ m/$ErrorArgumentsRetry[$j]/){
				$retryAttempt = true;
				print $tHandle "\nRetry Reason : $ErrorArgumentsRetry[$j]. retryAttempt:  $retryAttempt".$lineFeed;
				last;
			}
		}	
		if($retryAttempt){
			last;
		}
	}
	return 1;
}


#****************************************************************************************************************************
# Subroutine Name         : getFinalErrorFile
# Objective               : This subroutine creates a final ERROR file for each backupset, which has to be displayed in LOGS  
# Modified By             : Pooja Havaldar
#******************************************************************************************************************************/
sub getFinalErrorFile()
{
	$cancel = 0;
	if($exit_flag == 0){
		if(!-e $pidPath){
			$cancel = 1;
		}
	}
	
	my $failedWithReason = 0;
	my $errFinal = "";
	my $errMsgFinal = "";
	my $fileOpenFlag = 1;
	my $individual_errorfile = "$currentErrorFile";
	
	if($failedfiles_count > 0){
		open ERROR_FINAL, ">", $individual_errorfile."_FINAL" or $fileOpenFlag = 0;
		if(!$fileOpenFlag){
			return;
		}
		else{
			chmod 0777, $individual_errorfile."_FINAL";
			open BACKUP_RESTORE_ERROR, "<", $individual_errorfile or $fileOpenFlag = 0;
			if($fileOpenFlag){
				@individual_errorfileContents = <BACKUP_RESTORE_ERROR>;
				close BACKUP_RESTORE_ERROR;
			}
		}
		
		chomp(@failedfiles_array);
		chomp(@individual_errorfileContents);
		
		my $j = 0; 
		@failedfiles_array = sort @failedfiles_array;
		my $last_index = $#individual_errorfileContents;
	
		for($i = 0; $i <= $#failedfiles_array; $i++){
			$matched = 0;
			
			if($fileOpenFlag){
				#reset the initial and last limit for internal for loop for new item if required
				if($j > $last_index){
					$j = 0;
					$last_index = $#individual_errorfileContents;
				}
				
				#fill the last matched index for later use
				$index = $j;
				$failedfile = substr($failedfiles_array[$i],1);
				$failedfile = quotemeta($failedfile);
				
				#try to find a match between start and end point of error file
				for(;$j <= $last_index; $j++){
					if($individual_errorfileContents[$j] =~ /$failedfile/){
						$individual_errorfileContents[$j] =~ s/$failedfile//;
						print ERROR_FINAL "[".(localtime)."] [FAILED] [$failedfiles_array[$i]] Reason : $individual_errorfileContents[$j]".$lineFeed;
						#print $tHandle "\n printing in ERROR_FINAL with reason\n";
						$matched = 1;
						$failedWithReason++;	
							
						#got a match so resetting the last index 
						$last_index = $#individual_errorfileContents;
						$j++;
						last;
					}
				
					#if no match till last item and intial index is not zero try for remaining error file content
					if($j == $last_index && $index != 0){
						$j = 0;
						$last_index = $index;
						$index = $j;
					}
				}
			}
			
			if($matched == 0 and $exit_flag == 0 and $cancel == 0){
				print ERROR_FINAL "[".(localtime)."] [FAILED] [$failedfiles_array[$i]]".$lineFeed;
			}
		}
		
		close ERROR_FINAL;
	}
	
	if($exit_flag != 0 or $cancel != 0){
		$failedfiles_count = $failedWithReason;
	}
	unlink $individual_errorfile;
}

#****************************************************************************************************
# Subroutine Name         : process_term
# Objective               : The signal handler invoked when SIGTERM signal is received by the script       
# Created By              : Arnab Gupta
#*****************************************************************************************************/
sub process_term()
{
	writeParameterValuesToStatusFile();
	exit 0;
}

#****************************************************************************************************
# Subroutine Name         : writeParameterValuesToBackupStatusFile
# Objective               : This subroutine writes the value of the specified parameter to the Status File 
# Modified By             : Deepak Chaurasia
# Remodified By			  : Dhritikana
#*****************************************************************************************************/
sub writeParameterValuesToStatusFile()
{
	my $Count= 0;
	my $Synccount = 0;
	my $Errorcount = 0;

	# read the backup, sync and error count from status file
	$Count = getParameterValueFromStatusFile('COUNT_FILES_INDEX');
	$Synccount = getParameterValueFromStatusFile('SYNC_COUNT_FILES_INDEX');
	$Errorcount = getParameterValueFromStatusFile('ERROR_COUNT_FILES');
	
	# open status file to modify
	if(!open(STATUS_FILE, "> $statusFilePath")) {
		print $tHandle "Failed to open $statusFilePath, Reason:$! $lineFeed";
		return;
	}
	chmod 0777, $statusFilePath;
	autoflush STATUS_FILE; 
	
	# Calculate the backup, sync and error count based on new values
	if($jobType eq "BACKUP") {
		$Count += $fileBackupCount;
	} else {
		$Count += $fileRestoreCount;
	}
	
	$Synccount += $fileSyncCount;
	$Errorcount = $failedfiles_count;
	
	$statusHash{'COUNT_FILES_INDEX'} = $Count;
	$statusHash{'SYNC_COUNT_FILES_INDEX'} = $Synccount;
	$statusHash{'ERROR_COUNT_FILES'} = $Errorcount;
	$statusHash{'FAILEDFILES_LISTIDX'} = $failedfiles_index;
	$statusHash{'EXIT_FLAG_INDEX'} = $exit_flag;
	$statusHash{'PROGRESS_HEADER'} = 1;

	putParameterValueInStatusFile();
}

#****************************************************************************************************
# Subroutine Name         : RestoreOutputParse.
# Objective               : This function monitors and parse the evs output file and creates the App 
#							log file which is shown to user. 					
# Modified By             : Deepak Chaurasia
#*****************************************************************************************************/
sub RestoreOutputParse()
{
	my $fields_in_progress = 10;
	
	if(open(OUTFILE, ">> $outputFilePath")) {
		chmod 0777, $outputFilePath;  
		autoflush OUTFILE;
	}
	else {
		$Oflag = 1;
		print $tHandle CONST->{'FileOpnErr'}."\$outputFilePath : $outputFilePath, Reason:$! $lineFeed";
		return;
	}
	
	$progressHeader = getParameterValueFromStatusFile('PROGRESS_HEADER');
	if(!$flagToCheckSchdule && $progressHeader != 1) {
		my $header = "---------------------------------------------------------------------------------\n".
					"                       RESTORE PROGRESS                        \n".
					"---------------------------------------------------------------------------------\n".
					"FILE NAME | FILE SIZE | RESTORESET SIZE | TRANSFER RATE | PERCENTAGE | PROGRESS \n".
					"---------------------------------------------------------------------------------\n";
		print $header;
		$statusHash{'PROGRESS_HEADER'} = 1;
		putParameterValueInStatusFile();
	} else {
		if(!open(PROGRESSFILE, ">", $progressDetailsFilePath)) {
			$pflag = 1;
			print $tHandle CONST->{'FileOpnErr'}.$whiteSpace."\$progressDetailsFilePath: $progressDetailsFilePath Reason:$! $lineFeed";
			print CONST->{'FileOpnErr'}.$whiteSpace."\$progressDetailsFilePath: ".$progressDetailsFilePath." Reason:$! $lineFeed";
		}
		chmod 0777, $progressDetailsFilePath;
	}
	
	while (!$fileNotOpened) {
		if(-e $idevsOutputFile) {
			open TEMPOUTPUTFILE, "<", $idevsOutputFile and $fileNotOpened = 1;
			chmod 0777, $idevsOutputFile;
		}
		else{
			sleep(2);
		}
	}
	
	while (1) {
		$byteRead = read(TEMPOUTPUTFILE, $buffer, LIMIT);
		if($byteRead == 0) {
			if(-s $idevsErrorFile > 0){
				last;
			}
			sleep(2);
			seek(TEMPOUTPUTFILE, 0, 1);		#to clear eof flag
			next;
		}
		
		if("" ne $lastLine)	{		# need to check appending partial record to packet or to first line of packet
			$buffer = $lastLine . $buffer;
		}
		
		my @resultList = split /\n/, $buffer;
		my $bufIndex = @resultList;
		
		if($buffer !~ /\n$/) {      #keep last line of buffer only when it not ends with newline.
			$lastLine = $resultList[$#resultList];
			$bufIndex -= 1;
		}
		else {
			$lastLine = "";
		}
		
		for(my $cnt = 0; $cnt < $bufIndex; $cnt++) {
			my $tmpLine = $resultList[$cnt];
			if($tmpLine =~ /FILE IN SYNC/) {
				$fields_in_progress = 7;
			} elsif($tmpLine =~ /FULL/ or $tmpLine =~ /INCREMENTAL/) {
				$fields_in_progress = 10;
			}
			my @fields = split("\\] \\[",$tmpLine,$fields_in_progress);
			my $total_fields = @fields;
			
			if($total_fields == $fields_in_progress) {
				$fields[0] =~ s/^.//; # remove starting character [ from first field
				
				$fields[$fields_in_progress-1] =~ s/.$//; # remove last character ] from last field
				#chop($fields[$fields_in_progress-1]);
				
				# remove spaces from beginning from required fields
				$fields[0] =~ s/^\s+//;
				#$fields[5] =~ s/^\s+//;
				
				#my $keyString = "$pathSeparator$fields[6]";
				my $keyString = undef;
				
				my $restoreFinishTime = localtime;
				my $fileSize = convertFileSize($fields[0]);
				$keyString = $pathSeparator.$fields[$fields_in_progress-1];
				
				if($tmpLine =~ /FILE IN SYNC/) { 		# check if file in sync
					$perCent = $fields[$fields_in_progress-4];
					$kbps = $fields[$fields_in_progress-3];
				}
				elsif($tmpLine =~ /FULL/ or $tmpLine =~ /INCREMENTAL/) {  	# check if file is backing up as full or incremental
					$perCent = $fields[$fields_in_progress-5];
					$kbps = $fields[$fields_in_progress-4];
				}
				my $pKeyString = $keyString;
				if($tmpLine =~ m/$operationComplete/) {
					if($tmpLine =~ /FILE IN SYNC/) { 		# check if file in sync
						if(defined($fileSetHash{$keyString})) {
							$fileSetHash{$keyString} = 1;
						} else {
							$fullPath = getFullPathofFile($keyString);
						}
						$fileSyncCount++;
						if($relative eq NORELATIVE) {
							my $indx = rindex ($pKeyString, '/');
							$pKeyString = substr($pKeyString, $indx);
						}
					}
					elsif($tmpLine =~ /FULL/ or $tmpLine =~ /INCREMENTAL/) {  	# check if file is backing up as full or incremental
						if(defined($fileSetHash{$keyString})) {
							$fileSetHash{$keyString} = 1;
						} else {
							$fullPath = getFullPathofFile($keyString);
						}
						$fileRestoreCount++;
						print OUTFILE "[$restoreFinishTime] [$fields[$fields_in_progress-2] Restore] [SUCCESS] [$keyString] [$fileSize]",$lineFeed;
					}
					else {
						addtionalErrorInfo(\$currentErrorFile, \$tmpLine);
					}
				} 
								
				if($tmpLine ne $prevLine) {
					$lineFeedPrinted = false;
					#if($prevFile ne $keyString) {
					$fields[0] =~ s/^\s+|\s+$//;
					$fields[2] =~ s/^\s+|\s+$//;
					#}
				}
				
				if($flagToCheckSchdule && !$pflag) {
					$progress = $pKeyString.$whiteSpace.$perCent.$whiteSpace.$fields[0].$whiteSpace.$fields[2].$whiteSpace."$kbps";
					seek(PROGRESSFILE, 0, 0);
					print PROGRESSFILE $progress; 
				} elsif(!$flagToCheckSchdule) {	
						displayProgressBar($pKeyString, $perCent, $fields[0], $fields[2], "$kbps");
				}
				$prevLine = $tmpLine;
				$prevFile = $keyString;
			}
			if($tmpLine =~ /$termData/ ) {
				close TEMPOUTPUTFILE;				
				unlink($idevsOutputFile);
				$skipFlag = 1;
			}
			
			if($tmpLine !~ m/building file list/ and 
			$tmpLine !~ m/=============/ and 
			$tmpLine !~ m/connection established/ and 
			$tmpLine !~ m/bytes  received/ and 
			$tmpLine !~ m/receiving file list/ and 
			$tmpLine !~ m/\| FILE SIZE \| TRANSFERED SIZE \| TOTAL SIZE \|/ and
			$tmpLine !~ m/\%\]\s+\[/ and
			$tmpLine !~ m/$termData/) {
				if($tmpLine ne ''){
					$errStr = $tmpLine;
					addtionalErrorInfo(\$currentErrorFile, \$tmpLine);
				}
			}               
		}
		
		if($skipFlag){
			#if($flagToCheckSchdule && !$pflag) {
			#	my $end = "FileName=END_OF_PROCESS".$whiteSpace."PercentComplete=100".$lineFeed;
			#	seek(PROGRESSFILE, 0, 0);
			#	print PROGRESSFILE $end; 
			#}
			last;
		}
	}
	
	if(!$Oflag) {
		close OUTFILE;
	}
	
	if(!$pflag) {
		close PROGRESSFILE;
	}
}

#****************************************************************************************************
# Subroutine Name         : writeToCrontab.
# Objective               : Append an entry to crontab file.				
# Modified By             : Dhritikana.
#*****************************************************************************************************/
sub writeToCrontab {
	@linestemp_file = grep !/Schedule/, @linestemp_file;
	my $cron = "/etc/crontab";
	if(!open CRON, ">", $cron) {
		exit 1;
	}
	print CRON @linestemp_file;
	close(CRON);
	exit 0;
}

