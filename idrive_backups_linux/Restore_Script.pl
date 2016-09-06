#!/usr/bin/perl

# importing modules
require 'header.pl';
use FileHandle;
use Sys::Hostname;
use POSIX;

use constant false => 0;
use constant true => 1;

use Constants 'CONST';

# use of constants
use constant CHILD_PROCESS_STARTED => 1;
use constant CHILD_PROCESS_COMPLETED => 2;

use constant LIMIT => 2*1024;
use constant FILE_MAX_COUNT => 1000;
use constant RELATIVE => "--relative";
use constant NORELATIVE => "--no-relative";

# use constant SEARCH => "Search";
use constant SPLIT_LIMIT_SEARCH_OUTPUT => 6;
use constant SPLIT_LIMIT_ITEMS_OUTPUT => 2;
use constant SPLIT_LIMIT_INFO_LINE => 3;

use constant RESTORE_PID_FAIL => 5;
use constant OUTPUT_PID_FAIL => 6;
use constant PID_NOT_EXIST => 7;
use constant RESTORE_SUCCESS => 8;

use constant REMOTE_SEARCH_FAIL => 12;
use constant REMOTE_SEARCH_CMD_ERROR => 13;
use constant REMOTE_SEARCH_OUTPUT_PARSE_FAIL => 14;
use constant REMOTE_SEARCH_SUCCESS => 15;
use constant CREATE_THOUSANDS_FILES_SET_SUCCESS => 16;
use constant REMOTE_SEARCH_THOUSANDS_FILES_SET_ERROR => 17;

# Index number for arrayParametersStatusFile
use constant COUNT_FILES_INDEX => 0;
use constant SYNC_COUNT_FILES_INDEX => 1;
use constant ERROR_COUNT_FILES => 2;
use constant FAILEDFILES_LISTIDX => 3;
use constant RETRY_ATTEMPT_INDEX => 4;
#use constant ERR_MSG_INDEX => 4;
use constant EXIT_FLAG_INDEX => 4;

# Status File Parameters
my @statusFileArray = (		"COUNT_FILES_INDEX",
							"SYNC_COUNT_FILES_INDEX",
							"ERROR_COUNT_FILES",
							"FAILEDFILES_LISTIDX",
							"RETRY_ATTEMPT_INDEX",
							"EXIT_FLAG"
							#"ERR_MSG_INDEX"
						);
                                

#Indicates whether child process#
#has started/completed          #
my $childProcessStatus : shared;
$childProcessStatus = undef;

my $errorFilePresent = false;
my $invalidCharPresent = false;
my $lineCount;
my $prevLineCount;
my $cancelFlag = false;
my $headerWrite = 0;
my $restoreUtfFile = undef;
my $generateFilesPid = undef;
my $prevTime = time();
my $countErrorFile = 0; 					#Count of files which could not be restored due to specified errors #
my $maxNumRetryAttempts = 5;				#Maximum number of times the script should try to restore in case of errors#
my $filesonlycount = 0;
my $prevFailedCount = 0;
my $relative = 0;
my $noRelIndex = 0;
my $exitStatus = 0;
my $retrycount = 0;
my $RestoreItemCheck = "RestoresetFile.txt.item";
$location = $restoreLocation;
my $RestoresetFile_new = undef;
my $RestoreFileName = $RestoresetFile;
my $RestoresetFile_relative = "RestoreFileName_Rel";
my $filesOnly = "RestoreFileName_filesOnly";
my $noRelativeFileset = "RestoreFileName_NoRel";
$jobType = "Restore";

#Subroutine that processes SIGINT, SIGTERM and SIGTSTP#
#signal received by the script during restore#
$SIG{INT} = \&process_term;
$SIG{TERM} = \&process_term;
$SIG{TSTP} = \&process_term;
$SIG{QUIT} = \&process_term;

my ($appTypeSupport,$appType) = getAppType();

# Trace Log Entry #
my $curFile = basename(__FILE__);
print $tHandle "$lineFeed File: $curFile $lineFeed",
                "---------------------------------------- $lineFeed";
                
#Verifying if Restore scheduled or manual job
my $flagToCheckSchdule = undef;
if(${ARGV[0]} eq "Restore") {
	$userName = $ARGV[1];
	$pwdPath = $pwdPath."_SCH";
	$pvtPath = $pvtPath."_SCH";
	$flagToCheckSchdule = 1;
	$taskType = "Scheduled"; 
	$DefaultSet = "$usrProfilePath/$userName/DefaultRestoreset";
	my $flag = copy($RestoreFileName,$DefaultSet);
	if(!$flag) {
		print  $tHandle $lineFeed." Couldn't create Default $jobType set: $DefaultSet from 	$RestoreFileName, Reason: $!".$lineFeed;
		exit(1);
	}
	$RestoreFileName = $DefaultSet;
	chmod 0777, $RestoreFileName;
	print $tHandle CONST->{'BckupSchRunning'}.$lineFeed;
} else {
	$taskType = "Manual";
	my $pvtParam = "PVTKEY";
	getParameterValue(\$pvtParam, \$hashParameters{$pvtParam});
	my $pvtKey = $hashParameters{$pvtParam};
	if(! -e $pwdPath or ($pvtKey ne "" and ! -e $pvtPath)){
		print CONST->{'PlLogin'}.$appType.CONST->{'AccLogin'}.$lineFeed;
        system("/usr/bin/perl logout.pl 1");
        exit(1);
	}
}

#Defining and creating working directory
$jobRunningDir = "$usrProfilePath/$userName/Restore/$taskType";
if(!-d $jobRunningDir) {
	mkpath($jobRunningDir);
	chmod 0777, $jobRunningDir;
}

$pidPath = "$jobRunningDir/pid.txt";
#Checking if another job in progress
if(!pidAliveCheck()) {
	exit 1;
}

#Loading global variables
$statusFilePath = "$jobRunningDir/STATUS_FILE";
$search = "$jobRunningDir/Search";
my $info_file = $jobRunningDir."/info_file";
$retryinfo = "$jobRunningDir/".$retryinfo;
$evsTempDirPath = "$jobRunningDir/evs_temp";
$temp_file = "$jobRunningDir/operationsfile.txt"; 
my $failedfiles = $versionRestoresetFile."/".$failedFileName;
$idevsOutputFile = "$jobRunningDir/output.txt";
$idevsErrorFile = "$jobRunningDir/error.txt";
$RestoresetFile_relative = $jobRunningDir."/".$RestoresetFile_relative;
$noRelativeFileset	= $jobRunningDir."/".$noRelativeFileset;
$filesOnly	= $jobRunningDir."/".$filesOnly;

# pre cleanup for all intermediate files and folders.
`rm -rf $RestoresetFile_relative* $noRelativeFileset* $filesOnly* $info_file $retryinfo ERROR $statusFilePath $failedfiles*`;

$errorDir = $jobRunningDir."/ERROR";
if(!-d $errorDir) {
	my $ret = mkdir($errorDir);
	if($ret ne 1) {
		print $tHandle "Couldn't create $errorDir: $!\n"; #Ask
		exit 1;
	}
	chmod 0777, $errorDir;
}   				     
        
# Deciding Restore set File based on normal restore or version restore
if(${ARGV[0]} eq 2) {
		$RestoreFileName = $jobRunningDir."/versionRestoresetFile.txt";
}

my $serverAddress = verifyAndLoadServerAddr();
my $encType = checkEncType($flagToCheckSchdule);
createUpdateBWFile();
checkPreReq();
createLogFiles("RESTORE");

$info_file = $jobRunningDir."/info_file";
$failedfiles = $jobRunningDir."/".$failedFileName;

createRestoreTypeFile();
$mail_content_head = writeLogHeader($flagToCheckSchdule);
startRestore();
exit_cleanup($errStr);

#****************************************************************************************************
# Subroutine Name         : checkPreReq.
# Objective               : This function will check if prequired files before doing restore.					
# Added By				  : Dhritikana
#*****************************************************************************************************/
sub checkPreReq {
	my $err_string = checkBinaryExists();
	if($err_string eq "") {
		if(!defined $RestoreFileName or $RestoreFileName eq "") {
			$err_string = CONST->{'RstPathMissing'}.$lineFeed.CONST->{'InstrctReadMe'}.$lineFeed;
		} elsif(!-e $RestoreFileName) {
			$err_string = CONST->{'RstFileMissing'}.$lineFeed.CONST->{'InstrctReadMe'}.$lineFeed;
		} elsif( !-s $RestoreFileName ) {
			$err_string = CONST->{'RestoreSetEmpty'}.CONST->{'InstrctReadMe'}.$lineFeed;
		}
	}

	if($err_string ne "") {
		$errStr = $err_string;
		print $err_string;
		print $tHandle $err_string;
		
		$subjectLine = "$taskType Restore Email Notification "."[$userName]"." [Failed Restore]";
		$status = "FAILURE";
		sendMail($subjectLine);
		rmtree($errorDir);  
		unlink $pidPath;
		exit 1;
	}
	verifyRestoreLocation(\$restoreLocation);
}

#****************************************************************************************************
# Subroutine Name         : startRestore
# Objective               : This function will fork a child process to generate restoreset files and get
#							count of total files considered. Another forked process will perform main 
#							restore operation of all the generated restoreset files one by one.
# Added By				  : 
#*****************************************************************************************************/
sub startRestore {	
	$generateFilesPid = fork();
	if(!defined $generateFilesPid) {
		$errStr = "Unable to start generateRestoresetFiles operation";
		print $tHandle "Cannot fork() child process, Reason:$! $lineFeed";
		return;
	}
	
	if($generateFilesPid == 0) {
		generateRestoresetFiles();
	}

	#autoflush $tHandle;
	close(FD_WRITE);
START:
	if(!open(FD_READ, "<", $info_file)) {
		$errStr = CONST->{'FileOpnErr'}." $info_file to read, Reason:$!";
		print $tHandle $errStr.$lineFeed;
		return;
	}
	
	my $lastFlag = 0;
	while (1) {
		$line = <FD_READ>;
		
		if($line eq "") {
			sleep(1);
			seek(FD_READ, 0, 1);		#to clear eof flag
			next;
		}
		
		chomp($line);
		$line =~ m/^[\s\t]+$/;
		#space and tab space also trim 

		if($lastFlag eq 1) {
			last;
		}
		
		if($line =~ m/^TOTALFILES/) {
			$totalFiles = $line;
			$totalFiles =~ s/TOTALFILES//;
			print $tHandle "\n totalfile in parent = $totalFiles \n";
			$lastFlag = 1;
			#last;
		}
		else {
			my $RestoreRes = doRestoreOperation($line);
			if(RESTORE_SUCCESS ne $RestoreRes) {
				$exitStatus = 1;
				last;
			} 
		}
		if( !-e $pidPath) {
			last;
		}
	}
	$nonExistsCount = $line;
	$nonExistsCount =~ s/FAILEDCOUNT//;
	close FD_READ;
	waitpid($generateFilesPid,0);
	undef @linesStatusFile;
	
	if($totalFiles == 0 or $totalFiles !~ /\d+/) {
		my $fileCountCmd = "cat $info_file | grep \"^TOTALFILES\"";
		$totalFiles = `$fileCountCmd`; 
		$totalFiles =~ s/TOTALFILES//;
		
		if($totalFiles == 0 or $totalFiles !~ /\d+/){
			print $tHandle "\n Unable to get total files count  1\n";
		}
	} 
	print $tHandle "\n totalFiles=============$totalFiles\n";
	
	if(-s $retryinfo > 0 && -e $pidPath && $retrycount <= $maxNumRetryAttempts && $exitStatus == 0) {
		if($retrycount == $maxNumRetryAttempts) {
			my $index = "-1";
			$statusHash{'FAILEDFILES_LISTIDX'} = $index;
			putParameterValueInStatusFile();
		}
		move($retryinfo, $info_file);
		updateRetryCount();
		
		#append total file number to info
		if(!open(INFO, ">>",$info_file)){
			$errStr = CONST->{'FileOpnErr'}." $info_file, Reason $!".$lineFeed;
			return;
		}
		print INFO "TOTALFILES $totalFiles\n";
		close INFO;
		chmod 0777, $info_file;
		goto START;
	}
}

#****************************************************************************************************
# Subroutine Name         : checkRestoreItem.
# Objective               : This function will check if restore items are files or folders
# Added By				  : Dhritikana
#*****************************************************************************************************/
sub checkRestoreItem {
	if(!open(RESTORELIST, $RestoreFileName)){
		print $tHandle CONST->{'FileOpnErr'}." $RestoreFileName , Reason: $!\n";
		return 0;
	}
	if(!open(RESTORELISTNEW, ">", $RestoreItemCheck)){
		print $tHandle CONST->{'FileOpnErr'}." $RestoreItemCheck , Reason: $!\n";
		return 0;
	}
	
	while(<RESTORELIST>) {
		chomp($_);
		$_ =~ s/\s+//;
		if($_ eq "") {
			next;
		}
		my $rItem = "";
		if(substr($_, 0, 1) ne "/") {
			$rItem = $restoreHost."/".$_;
		} else {
			$rItem = $restoreHost.$_;
		}
	
		print RESTORELISTNEW $rItem.$lineFeed;
	}
	close(RESTORELIST);
	close(RESTORELISTNEW);

GETSTAT:
	my @itemsStat = undef;
	my $checkItemUtf = getOperationFile( $itemStatOp, $RestoreItemCheck);
	
	if(!$checkItemUtf) {
		print $tHandle $errStr;
		return @itemsStat;
	}
	
	$checkItemUtf =~ s/\'/\'\\''/g; 
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$checkItemUtf."'".$whiteSpace.$errorRedirection;;
	my @itemsStat = `$idevsutilCommandLine`;
	# update server address if cmd failed due to wrong evs server address
	if(updateServerAddr()){
		goto GETSTAT;
	}
	unlink($checkItemUtf);
	unlink($RestoreItemCheck);
	return @itemsStat;
}

#****************************************************************************************************
# Subroutine Name         : enumerateRemote.
# Objective               : This function will search remote files for folders.
# Added By				  : Avinash Kumar.
# Modified By 			  : Dhritikana
#*****************************************************************************************************/
sub enumerateRemote {
	my $remoteFolder  = $_[0];
	my $searchForRestore = 1;
   
    # remove / from begining for folder to avoid // while creating utf8 file.
	#$remoteFolder = substr($remoteFolder, 1);
	
	if(substr($remoteFolder, -1, 1) eq "/") {
		chop($remoteFolder);
	}
			
	# final EVS command to execute
	#if(! -d SEARCH) {
	if(! -d $search) {
		#if(!mkdir(SEARCH)) {
		if(!mkdir($search)) {
			$errStr = "Failed to create search directory\n";
			return 0;
		}
		chmod 0777, $search;
	}
	
	my $searchOutput = $search."/output.txt";
	my $searchError = $search."/error.txt";
	
	#if(!chdir(SEARCH)) {
	#if(!chdir($search)) {
	#	$errStr = "chdir search failure\n";
	#	return 0;
	#}
	
START:
	my $searchUtfFile = getOperationFile($searchOp, $remoteFolder);
	if(!$searchUtfFile) {
		return 0;
	}
	
	$searchUtfFile =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$searchUtfFile."'".$whiteSpace.$errorRedirection;
	my $commandOutput = `$idevsutilCommandLine`;
	# EVS command execute
	$res = `$idevsutilCommandLine`;
	
	if("" ne $res){
		$errStr = "search cmd syntax error found\n";
		return REMOTE_SEARCH_CMD_ERROR;
	}

	# update server address if cmd failed due to wrong evs server address
	if(updateServerAddr($searchError)){
		goto START;
	}
	
	if(-s $searchError > 0) {
		$errStr = "Remote folder enumeration has failed.\n";
		return REMOTE_SEARCH_FAIL;
	}
	unlink($searchUtfFile);
	  
	# parse serach output.
	open OUTFH, "<", $searchOutput or ($errStr = "cannot open :$searchOutput: of search result for $remoteFolder");
	if($errStr ne ""){
		print $tHandle $errStr."\n";;
		return REMOTE_SEARCH_OUTPUT_PARSE_FAIL;
	}
	
	#if(!chdir("..")) {
	#	$errStr = "chdir from search to working directory failure\n";
	#	return 0;
	#}
	
	@files = <OUTFH>;
	chomp(@files);
	@files = splice(@files, 4, $#files - 5);		# remove comment lines as array elements that available in output.txt.
	
	foreach $line (@files) {
		@fileName = split(/\] \[/, $line, SPLIT_LIMIT_SEARCH_OUTPUT);		# split to get file name.
		chop($fileName[5]);			# remove lat character as ']'.
		$temp = $fileName[5];

		my $quoted_current_source = quotemeta($current_source);
		if($relative == 0) {
			if($current_source ne "/") {
				$temp =~ s/^$quoted_current_source//;
			}
			print $filehandle $temp.$lineFeed;
		}
		else {
			$current_source = "/";
			print RESTORE_FILE $temp.$lineFeed;
			$RestoresetFileTmp = $RestoresetFile_relative;
		}
		$totalFiles++;
		$filecount++;	
		if($filecount == FILE_MAX_COUNT) {
			if(!createRestoreSetFiles1k()){
				print $tHandle $errStr;
				return REMOTE_SEARCH_THOUSANDS_FILES_SET_ERROR;
			}
		}	
	}
	print $tHandle $errStr;
	return REMOTE_SEARCH_SUCCESS;
}

#****************************************************************************************************
# Subroutine Name         : generateRestoresetFiles.
# Objective               : This function will generate restoreset files.
# Added By				  : Dhritikana
#*****************************************************************************************************/
sub generateRestoresetFiles {
	#check if running for restore version pl, in that case no need of generate files.
	if(${ARGV[0]} eq 2) {
			$totalFiles = 1;
			$current_source = "/";
			
			print FD_WRITE "$RestoreFileName ".NORELATIVE." $current_source\n"; 
			goto GENEND;
	}
	
	my $traceExist = $errorDir."/traceExist.txt";
	if(!open(TRACEERRORFILE, ">>", $traceExist)) {
		print $tHandle CONST->{'FileOpnErr'}." $traceExist, Reason: $!. $lineFeed";
	}
	chmod 0777, $traceExist;
	
	$pidTestFlag = "GenerateFile";
	my @itemsStat = checkRestoreItem();
	
	$filesonlycount = 0;
	my $j = 0;
	my $idx = 0;
	
	if($#itemsStat ge 1) {
		chomp(@itemsStat);

		foreach my $tmpLine (@itemsStat) {
			my @fields = split("\\] \\[", $tmpLine, SPLIT_LIMIT_ITEMS_OUTPUT);
			my $total_fields = @fields;
					
			if($total_fields == SPLIT_LIMIT_ITEMS_OUTPUT) {
				
				$fields[0] =~ s/^.//; # remove starting character [ from first field
				$fields[$fields_in_progress-1] =~ s/.$//; # remove last character ] from last field
				$fields[0] =~ s/^\s+//; # remove spaces from beginning from required fields
				$fields[1] =~ s/^\s+//;
				
				if ($fields[1] eq "." or $fields[1] eq "..") {
					next;
				}
				
				if($fields[0] =~ /directory exists/) {
					chop($fields[1]);
					if($relative == 0) {
						$noRelIndex++;
						$RestoresetFile_new = $noRelativeFileset."$noRelIndex";
						$filecount = 0;
						$sourceIdx = rindex ($fields[1], '/');
						$source[$noRelIndex] = substr($fields[1],0,$sourceIdx);
						if($source[$noRelIndex] eq "") {
							$source[$noRelIndex] = "/";
						}
						$current_source = $source[$noRelIndex];
						if(!open $filehandle, ">>", $RestoresetFile_new){
							print $tHandle "\n cannot open $RestoresetFile_new to write ";
							exit 0;
						}
						chmod 0777, $RestoresetFile_new;
					}
					my $resEnumerate = 0;
					$resEnumerate = enumerateRemote($fields[1]);
					if(!$resEnumerate){
						print $tHandle "$errStr ". $fields[1].$lineFeed;
						goto GENEND;
					} 
					elsif(REMOTE_SEARCH_CMD_ERROR == $resEnumerate){
						print $tHandle "Search command failed due to syntax error for the folder ". $fields[1].$lineFeed;
						appendEnumerationError($fields[1]);
					}
					elsif(REMOTE_SEARCH_FAIL == $resEnumerate){
						print $tHandle "Search command failed for the folder ". $fields[1].$lineFeed;
						appendEnumerationError($fields[1]);
					}
					elsif(REMOTE_SEARCH_OUTPUT_PARSE_FAIL == $resEnumerate){
						print $tHandle "Search command output parsing failed for the folder ". $fields[1].$lineFeed;
						appendEnumerationError($fields[1]);
					}
					elsif(REMOTE_SEARCH_THOUSANDS_FILES_SET_ERROR == $resEnumerate){
						print $tHandle "Error in creating 1k files ". $fields[1].$lineFeed;
						goto GENEND;
					}
				
					if($relative == 0 && $filecount>0) {
						autoflush FD_WRITE;
						print FD_WRITE "$RestoresetFile_new ".RELATIVE." $current_source\n";
					}
				} elsif($fields[0] =~ /file exists/) {
					$current_source = "/";
					print RESTORE_FILE $fields[1].$lineFeed;
					
					if($relative == 0) {
						$filesonlycount++;
						$filecount = $filesonlycount;
					}
					else {
						$filecount++;
					}
					
					$totalFiles++;	
	
					if($filecount == FILE_MAX_COUNT) {
						$filesonlycount = 0;
						if(!createRestoreSetFiles1k("FILESONLY")){
							goto GENEND;
						}
					}
				} elsif ($fields[0] =~ /No such file or directory/) {
					$totalFiles++;	
					$nonExistsCount++; 
					print TRACEERRORFILE "[".(localtime)."] [FAILED] [$fields[1]]. Reason: No such file or directory".$lineFeed;
					next;
				}
			}
		}
	}
	
	if($relative == 1 && $filecount > 0){
		print FD_WRITE "$RestoresetFile_new ".RELATIVE." $current_source \n"; #[dynamic]
	}
	elsif($filesonlycount >0){
		$current_source = "/";
		print FD_WRITE "$RestoresetFile_Only ".NORELATIVE." $current_source\n"; #[dynamic]
	}
	
	GENEND:
	autoflush FD_WRITE;
	print FD_WRITE "TOTALFILES $totalFiles\n";
	print FD_WRITE "FAILEDCOUNT $nonExistsCount\n";
	close(FD_WRITE);
	close RESTORE_FILE;
	$pidTestFlag = "generateListFinish";
	close(TRACEERRORFILE);
	exit 0;
}

#****************************************************************************************************
# Subroutine Name         : createRestoreSetFiles1kcreateRestoreSetFiles1k.
# Objective               : This function will generate 1000 Backetupset Files
# Added By                : Pooja Havaldar
# Modified By			  : Avinash Kumar
#*****************************************************************************************************/
sub createRestoreSetFiles1k {
	my $filesOnlyFlag = $_[0];
	$Restorefilecount++;
	
	if($relative == 0) {
		if($filesOnlyFlag eq "FILESONLY") {
			$filesOnlyCount++;
			print FD_WRITE "$RestoresetFile_Only ".NORELATIVE." $current_source\n"; # 0
			$RestoresetFile_Only = $filesOnly."_".$filesOnlyCount;
			
			close RESTORE_FILE;
			if(!open RESTORE_FILE, ">", $RestoresetFile_Only) {
				print $tHandle CONST->{'FileOpnErr'}." $filesOnly to write, Reason: $!. $lineFeed";
				return 0;
			}	
			chmod 0777, $RestoresetFile_Only;
		}
		else 
		{
			print FD_WRITE "$RestoresetFile_new ".RELATIVE." $current_source\n"; 
			#print $tHandle "\n in no-relative RestoresetFile_new = $RestoresetFile_new and RestoresetFileTmp = $RestoresetFileTmp";
			$RestoresetFile_new =  $noRelativeFileset."$noRelIndex"."_$Restorefilecount";
			
			close $filehandle;
			if(!open $filehandle, ">", $RestoresetFile_new) {
				print $tHandle CONST->{'FileOpnErr'}." $RestoresetFile_new to write, Reason: $!. $lineFeed";
				return 0;
			}	
			chmod 0777, $RestoresetFile_new;
		}
	}	
	else {
		print FD_WRITE "$RestoresetFile_new ".RELATIVE." $current_source\n"; 
		$RestoresetFile_new = $RestoresetFile_relative."_$Restorefilecount";
		
		close RESTORE_FILE;
		if(!open RESTORE_FILE, ">", $RestoresetFile_new){
			print $tHandle CONST->{'FileOpnErr'}." $RestoresetFile_new to write, Reason: $!. $lineFeed";
			return 0;
		}
		chmod 0777, $RestoresetFile_new;
	}

	autoflush FD_WRITE;
	$filecount = 0;
	
	if($Restorefilecount%15 == 0){
		sleep(1);
	}
	return CREATE_THOUSANDS_FILES_SET_SUCCESS;
}

#***********************************************************************************************************
# Subroutine Name         :	doRestoreOperation
# Objective               :	Performs the actual task of restoring files. It creates a child process which executes
#                           the restore command. 
#							Creates an output thread which continuously monitors the temporary output file.
#							At the end of restore, it inspects the temporary error file if present.
#							It then deletes the temporary output file, temporary error file and the temporary
#							directory created by idevsutil binary.
# Added By                : 
#************************************************************************************************************
sub doRestoreOperation()
{
	$parameters = $_[0];
	@parameter_list = split / /,$parameters, SPLIT_LIMIT_INFO_LINE;
	#print $tHandle "\n RestoresetFileName: $parameter_list[0] , RelativeOp: $parameter_list[1] , Source: $parameter_list[2] \n";

	$restoreUtfFile = getOperationFile($restoreOp, $parameter_list[0] ,$parameter_list[1] ,$parameter_list[2], $encType);
	
	if(!$restoreUtfFile) {
		print $tHandle $errStr;
		return 0;
	}

	my $tmprestoreUtfFile = $restoreUtfFile;
	$tmprestoreUtfFile =~ s/\'/\'\\''/g;
	my $tmp_idevsutilBinaryPath = $idevsutilBinaryPath;
	$tmp_idevsutilBinaryPath =~ s/\'/\'\\''/g;
	
	# EVS command to execute for backup
	$idevsutilCommandLine = "\'$tmp_idevsutilBinaryPath\'".$whiteSpace.$idevsutilArgument.$assignmentOperator."\'$tmprestoreUtfFile\'".$whiteSpace.$errorRedirection;
	
	$pid = fork();
	if(!defined $pid) {
		$errStr = CONST->{'ForkErr'}.$whiteSpace.CONST->{"EvsChild"}.$lineFeed;
		return RESTORE_PID_FAIL;
	}
	
	if($pid == 0) 
	{
		if(-e $pidPath) {
			exec($idevsutilCommandLine);
			$errStr = CONST->{'DoRstOpErr'}.CONST->{'ChldFailMsg'};
			print $errStr;
			print $tHandle $errStr."\n";
			
			if(open(ERRORFILE, ">> $errorFilePath")) {
				autoflush ERRORFILE;
				
				print ERRORFILE $errStr;
				close ERRORFILE;
				chmod 0777, $errorFilePath;
			}
			else 
			{
				print $tHandle $lineFeed.CONST->{'FileOpnErr'}.$errorFilePath.", Reason:$! $lineFeed";
			}
		}
		exit 1;	
	}
	
	{
		lock $childProcessStatus;
		$childProcessStatus = CHILD_PROCESS_STARTED;       
	}   
		
	$pid_OutputProcess = fork();
	if(!defined $pid_OutputProcess) {
		$errStr = CONST->{'ForkErr'}.$whiteSpace.CONST->{"LogChild"}.$lineFeed;
		return OUTPUT_PID_FAIL;
	}
	
	if($pid_OutputProcess == 0) {
		if( !-e $pidPath) {
			exit 1;
		}
		
		# restore child process for output file parsing 
		if(!open(TEMP_FILE, ">",$temp_file)){
			$errStr = "Could not open file $temp_file, Reason:$!";
			print $tHandle $errStr;
			return 0;
		}
		print TEMP_FILE "RestoreOutputParse";
		close TEMP_FILE;
		chmod 0777, $temp_file;
		
		$isLocalRestore = 0;
		$workingDir = $currentDir;
		$workingDir =~ s/\'/\'\\''/g;
		my $tmpOpFilePath = $outputFilePath;
		$tmpOpFilePath =~ s/\'/\'\\''/g;
		my $tmpJobRngDir = $jobRunningDir;
		$tmpJobRngDir =~ s/\'/\'\\''/g;
		my $tmpRstSetFile = $parameter_list[0];
		$tmpRstSetFile =~ s/\'/\'\\''/g;
		my $tmpSrc = $parameter_list[2];
		$tmpSrc =~ s/\'/\'\\''/g;
		$fileChildProcessPath = $workingDir."/operations.pl";
		
		print $tHandle "Child Process: $perlPath $fileChildProcessPath \'$tmpJobRngDir\' \'$tmpOpFilePath\' \'$tmpErFilePath\' \"$isLocalRestore\" \"$flagToCheckSchdule\" \'$tmpPrgsFilePath\' \'$tmpRstSetFile\' \'$parameter_list[1]\' \'$tmpSrc\'";
		exec("cd \'$workingDir\'; perl \'$fileChildProcessPath\' \'$tmpJobRngDir\' \'$tmpOpFilePath\' \'$tmpRstSetFile\' \'$parameter_list[1]\' \'$tmpSrc\' ");
		$errStr = CONST->{'rstProcessFailureMsg'};
		print $errStr.$lineFeed;
		print $tHandle $errStr.$lineFeed;
		
		if (open(ERRORFILE, ">> $errorFilePath")) {
			autoflush ERRORFILE;
			print ERRORFILE $errStr;
			close ERRORFILE;
			chmod 0777, $errorFilePath;
		}
		else 
		{
			print $tHandle CONST->{'FileOpnErr'}.$whiteSpace.$errorFilePath." Reason :$! $lineFeed";
		}
	
		exit 1;
	}
	
	waitpid($pid,0);
	{
		updateServerAddr();
		
		if(open OFH, ">>", $idevsOutputFile){
			print OFH "CHILD_PROCESS_COMPLETED\n";
			close OFH;
			chmod 0777, $idevsOutputFile;
		}
		else
		{
			print $tHandle  CONST->{'FileOpnErr'}." $outputFilePath. Reason: $!";
			print  CONST->{'FileOpnErr'}." $outputFilePath. Reason: $!";
			return 0;
		}
		
		lock $childProcessStatus; 
		$childProcessStatus = CHILD_PROCESS_COMPLETED;
	}
	
	waitpid($pid_OutputProcess, 0);
	unlink($parameter_list[0]);
	unlink($idevsOutputFile);

	
	if(-e $errorFilePath && -s $errorFilePath) {
		return 0;
	}
	
	return RESTORE_SUCCESS;
}

#*******************************************************************************************************
# Subroutine Name         :	verifyRestoreLocation
# Objective               :	This subroutine verifies if the directory where files are to be restored exists.
#                           In case the directory does	not exist, it sets the restore location to the
#							current directory.		
# Added By                : 
#********************************************************************************************************
sub verifyRestoreLocation()
{
	my $restoreLocationPath = ${$_[0]};
	if(!defined $restoreLocationPath or $restoreLocationPath eq "") {
		${$_[0]} = $usrProfileDir."/Restore_Data";
	}
	
	my $posLastSlash = rindex $restoreLocationPath, $pathSeparator;
	my $dirPath = substr $restoreLocationPath, 0, $posLastSlash + 1;
	my $dirName = substr $restoreLocationPath, $posLastSlash + 1;
	
	if(-d $dirPath) { 
		foreach my $char (@invalidCharsDirName) {
			my $posInvalidChar = index $dirName, $char;
			
			if($posInvalidChar != -1) {    
				${$_[0]} = $usrProfileDir."/Restore_Data";
				last;
			}
		}
	}
	else {
		${$_[0]} = $usrProfileDir."/Restore_Data";
	}
}

#*******************************************************************************************
# Subroutine Name         :	process_term
# Objective               :	The signal handler invoked when SIGINT or SIGTERM
#                           signal is received by the script 
# Added By                : 
#******************************************************************************************
sub process_term()
{
	unlink($pidPath);
	cancelSubRoutine();
}

#***********************************************************************************************************
# Subroutine Name         	:	cancelSubRoutine
# Objective               	:	In case the script execution is canceled by the user, the script should
#                           terminate the execution of the binary and perform cleanup operation. 
#							It should then generate the restore summary report, append the contents of the
#							error file to the output file and delete the error file.
# Added By				  	: Arnab Gupta
# Modified By				: Dhritikana. 
#************************************************************************************************************
sub cancelSubRoutine()
{
	if($pidTestFlag eq "GenerateFile")  {
		#if info file doesn't have TOTALFILE then write to info
		open FD_WRITE, ">>", $info_file or (print $tHandle CONST->{'FileOpnErr'}." $info_file to write, Reason:$!"); # and die);
		autoflush FD_WRITE;
		print FD_WRITE "TOTALFILES $totalFiles\n";
		print FD_WRITE "FAILEDCOUNT $nonExistsCount\n";
		close(FD_WRITE);
		close RESTORE_FILE;
		exit 0;
	} 
	
	if($totalFiles == 0 or $totalFiles !~ /\d+$/) {
		my $fileCountCmd = "cat $info_file | grep \"^TOTALFILES\"";
		$totalFiles = `$fileCountCmd`; 
		$totalFiles =~ s/TOTALFILES//;
	}	

	if($totalFiles == 0 or $totalFiles !~ /\d+$/){
		print $tHandle "\n Unable to get total files count 2 \n";
	}
	
	if($nonExistsCount == 0) {
		my $nonExistCheckCmd = "cat $info_file | grep \"^FAILEDCOUNT\"";
		$nonExistsCount = `$nonExistCheckCmd`; 
		$nonExistsCount =~ s/FAILEDCOUNT//;
	}
	
	my $evsCmd = "ps -elf | grep \"$idevsutilBinaryName\" | grep \'$backupUtfFile\'";
	$evsRunning = `$evsCmd`;
	@evsRunningArr = split("\n", $evsRunning);
	
	foreach(@evsRunningArr) {
		if($_ =~ /$evsCmd|grep/) {
			next;
		}
		my @lines = split(/[\s\t]+/, $_);
		my $pid = $lines[3];

		$scriptTerm = system("kill -9 $pid");
		if(defined($scriptTerm)) {
			if($scriptTerm != 0 && $scriptTerm ne "") {
				my $msg = CONST->{'KilFail'}." Restore\n";
				print $tHandle $msg;
			}
		}
	}
	exit_cleanup($errStr);
}

#****************************************************************************************************
# Subroutine Name         : exit_cleanup.
# Objective               : This function will execute the major functions required at the time of exit 
# Added By                : Deepak Chaurasia
# Modified By 			  : Dhritikana
#*****************************************************************************************************/
sub exit_cleanup {
	$successFiles = getParameterValueFromStatusFile('COUNT_FILES_INDEX');
	$syncedFiles = getParameterValueFromStatusFile('SYNC_COUNT_FILES_INDEX');
	$failedFilesCount = getParameterValueFromStatusFile('ERROR_COUNT_FILES');
	$exit_flag = getParameterValueFromStatusFile('EXIT_FLAG_INDEX');
	
	if($errStr eq "" and -e $errorFilePath) {
		open ERR, "<$errorFilePath" or print $tHandle CONST->{'FileOpnErr'}."errorFilePath in exit_cleanup: $errorFilePath, Reason: $!".$lineFeed;
		$errStr .= <ERR>;
		close(ERR);
		chomp($errStr);
	}
	
	if(!-e $pidPath) {
		$cancelFlag = 1;
		
		# In childprocess, if we exit due to some exit scenario, then this exit_flag will be true with error msg
		@exit = split("-",$exit_flag,2);
		#print $tHandle "\n exit = :$exit[0]: and $exit[1] \n";
		
		if(!$exit[0]) {
			if($flagToCheckSchdule) {
				$errStr = "Operation could not be completed. Reason : Operation Cancelled due to Cut off.";
			}
			else {
				$errStr = "Operation could not be completed, Reason: Operation Cancelled by User.";
			}
		} else {
			if($exit[1] ne ""){
				$errStr = $exit[1];
			}
		}
	}
	
	unlink($pidPath);
	writeOperationSummary($restoreOp);	
	unlink($idevsOutputFile);
	unlink($idevsErrorFile);
	unlink($restoreUtfFile);
	unlink($statusFilePath);
	unlink($retryinfo);
	unlink($temp_file);
	unlink($progressDetailsFilePath);
	if(-e $RestoreItemCheck) {
		unlink($RestoreItemCheck);
	}
	rmtree($evsTempDirPath);
	rmtree(SEARCH);
	rmtree($search);
	if(-d $errorDir) {
		rmtree($errorDir); 
	}
	restoreRestoresetFileConfiguration();
	
	my ($subjectLine) = getOpStatusNeSubLine();
	my $finalOutFile = $outputFilePath."_".$status;
	move($outputFilePath, $finalOutFile);
	$outputFilePath = $finalOutFile;
	
	sendMail($subjectLine);
	terminateStatusRetrievalScript();
	exit 0;
}

#******************************************************************************************************************
# Subroutine Name         : getOpStatusNeSubLine.
# Objective               : This subroutine returns restore operation status and email subject line
# Added By                : Dhritikana
#******************************************************************************************************************/
sub getOpStatusNeSubLine()
{
	my $subjectLine= "";
	my $totalNumFiles = $filesConsideredCount-$failedFilesCount;
	
	if($cancelFlag){
		$status = "ABORTED";
		$subjectLine = "$taskType Restore Email Notification "."[$userName]"."[Aborted Restore]";
	}
	elsif($filesConsideredCount == 0){
		$status = "FAILURE";
		$subjectLine = "$taskType Restore Email Notification "."[$userName]"."[Failed Restore]";
	}
	elsif($failedFilesCount == 0 and $filesConsideredCount > 0)
	{
		$status = "SUCCESS";
		$subjectLine = "$taskType Restore Email Notification "."[$userName]"."[Successful Restore]";
	}
	else {
		if(($failedFilesCount/$filesConsideredCount)*100 <= 5){				  
			$status = "SUCCESS*";
			$subjectLine = "$taskType Restore Email Notification "."[$userName]"."[Successful* Restore]";
		}
		else {
			$status = "FAILURE";
			$subjectLine = "$taskType Restore Email Notification "."[$userName]"."[Failed Restore]";
		}
	}
	return ($subjectLine);
}

#*******************************************************************************************************
# Subroutine Name         :	restoreRestoresetFileConfiguration
# Objective               :	This subroutine moves the RestoresetFile to the original configuration.			
# Added By                : 
#********************************************************************************************************
sub restoreRestoresetFileConfiguration()
{
	if($RestoresetFile_relative ne "") {
		unlink <$RestoresetFile_relative*>;
	}
	if($noRelativeFileset ne "") {
		unlink <$noRelativeFileset*>;
	}
	if($filesOnly ne "") {	
		unlink <$filesOnly*>;
	}
	if($failedfiles ne "") {	
		unlink <$failedfiles*>;
	}
	unlink $info_file;
}

#*******************************************************************************************************
# Subroutine Name         :	updateServerAddr
# Objective               :	handling wrong server address error msg	
# Added By                : Dhritikana
#********************************************************************************************************
sub updateServerAddr {
	my $tempErrorFileSize = undef;
	if($_[0]) {
		$tempErrorFileSize = -s $_[0];
	} else {
		$tempErrorFileSize = -s $idevsErrorFile;
	}
	if($tempErrorFileSize > 0) {
		my $errorPatternServerAddr = "unauthorized user";
		open EVSERROR, "<", $idevsErrorFile or (print $tHandle "\n Failed to open error.txt\n");
		$errorContent = <EVSERROR>;
		close EVSERROR;
		
		if($errorContent =~ m/$errorPatternServerAddr/){
			getServerAddr();
			return 1;
		}
	}
}

#****************************************************************************************************
# Subroutine Name         : appendEnumerationError.
# Objective               : Enumeration of a folder from restore set file gets fail then write 
#							proper error message to log file.
# Added By                : Avinash Kumar.
#*****************************************************************************************************/
sub appendEnumerationError()
{
	my $searchErrMsg = "[".(localtime)."]". "[".$_[0]."] Failed. Reason: Search has failed for the item.$lineFeed";
	# open log file to append serach failure message.
	if (!open(OUTFILE, ">> $outputFilePath")) { 
		print $tHandle "Could not open file $outputFilePath to append search error message for folder ".$_[0].", Reason:$!$lineFeed";
	}
	else {
		print OUTFILE $searchErrMsg;
		close OUTFILE;
		chmod 0777, $outputFilePath;
	}
}

#*******************************************************************************************************
# Subroutine Name         :	createRestoreTypeFile
# Objective               :	Create files respective to restore types (relative or no relative)
# Added By                : Dhritikana
#********************************************************************************************************
sub createRestoreTypeFile {
	#opening info file for generateBackupsetFiles function to write backup set information and for main process to read that information
	if(!open(FD_WRITE, ">", $info_file)){
		$errStr = "Could not open file $info_file to write, Reason:$!\n";
		print $tHandle $errStr and die;
	}
	chmod 0777, $info_file;
	
	#Restore File name for mirror path
	if($relative != 0) {
		$RestoresetFile_new =  $RestoresetFile_relative;
			
		if(!open RESTORE_FILE, ">>", $RestoresetFile_new) {
			print $tHandle CONST->{'FileOpnErr'}." $RestoresetFile_new to write, Reason:$!. $lineFeed";
			print CONST->{'FileOpnErr'}." $RestoresetFile_new to write, Reason:$!. $lineFeed";
			exit(1);
		}
		chmod 0777, $RestoresetFile_new;
	}
	else {
		#Restore File Name only for files
		$RestoresetFile_Only =  $filesOnly;
		
		if(!open RESTORE_FILE, ">>", $RestoresetFile_Only) {
			print $tHandle CONST->{'FileOpnErr'}." $RestoresetFile_Only to write, Reason:$!. $lineFeed";
			exit(1);
		}
		chmod 0777, $RestoresetFile_Only;
		
		$RestoresetFile_new =  $noRelativeFileset;
	}
}

#*******************************************************************************************************
# Subroutine Name         :	updateRetryCount
# Objective               :	updates retry count based on recent backup files.
# Added By                : Avinash
# Modified By             : Dhritikana
#********************************************************************************************************/
sub updateRetryCount()
{
	my $curFailedCount = 0;
	my $currentTime = time();

	$curFailedCount = getParameterValueFromStatusFile('ERROR_COUNT_FILES');
		
	if($prevFailedCount == 0 or $curFailedCount < $prevFailedCount) {
		$retrycount = 0;
	}
	else {
		if($currentTime-$prevTime < 120) {
			#print "Time Diff: ".($currentTime-$prevTime)."\n";
			sleep 300;
		}
		$retrycount++;
	}
	
	#assign the latest backuped and synced value to prev.
	$prevFailedCount = $curFailedCount;
	$prevTime = $currentTime;
}
