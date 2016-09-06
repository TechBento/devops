#!/usr/bin/perl

use Cwd;
use Tie::File;
use File::Copy;
use File::Basename;
use File::Path;
use IO::Handle;
use Fcntl;
use Constants 'CONST';

#use warnings;
#use strict;

our $tHandle;
our $logger;
our $lineFeed = "\n";
our $currentDir = getcwd;

#######################################################################
# APP_TYPE_SUPPORT should be ibackup for ibackup and idrive for idrive#
# APP_TYPE should be IBackup for ibackup and IDrive for idrive        #
#######################################################################
#use constant APP_TYPE_SUPPORT => "idrive";
#use constant APPTYPE => "IDrive";

#Configuration File Path#
our $confFilePath = "./CONFIGURATION_FILE";

#Array containing the lines read from Configuration File#
my @linesConfFile = ();

###############################
#Hash to hold the values of   #
#Configuration File Parameters#
###############################
my %hashParameters = (
                       "USERNAME" => undef,
                       "PROXY" => undef,
                       "LOGDIR" => undef,
                       "PVTKEY" => undef,
                       "BACKUPSETFILEPATH" => undef,
                       "NOTIFICATIONFLAG" => undef,
                       "EMAILADDRESS" => undef,
                       "FULLEXCLUDELISTFILEPATH" => undef,
                       "PARTIALEXCLUDELISTFILEPATH" => undef,
                       "REGEXEXCLUDEFILEPATH" => undef,
				       "BACKUPLOCATION" => undef,
				       "RETAINLOGS" => undef,
				       "BWTHROTTLE" => undef,
				       "RESTORESETFILEPATH" => undef,                               
                       "RESTORELOCATION" => undef,
	    		       "RESTOREFROM" => undef,				
	    		       "BACKUPPATHTYPE" => undef   
                     );

##################################
#Operation Type                  #
##################################
my $versionNumber = "Version 2.4";
our $backupOp = 1;
our $restoreOp = 2;
our $validateOp = 3;
our $getServerAddressOp = 4;
our $authListOp = 5;
our $configOp = 6;
our $getQuotaOp = 7;
our $propertiesOp = 8;
our $speedOp = 9;
our $createDirOp = 10;
our $searchOp = 11;
our $renameOp = 12;
our $itemStatOp = 13;
our $versionOp = 14;
our $perlPath = "";
our $psPath = "";
our $pidIdx = "";
our $cronSeparator = "";
our $whiteSpace = " ";
our $assignmentOperator = "=";
our $fileOpenStatus = 0;
our $idevsutilArgument = "--utf8-cmd";
my $encTypeDir = "";

our $userCancelStr = CONST->{'OpUsrCancel'};
our @invalidCharsDirName = ("/",">","<","|",":","&"); #Array containing the characters which should not be present in a Directory name#

our $idevsutilBinaryName = "idevsutil";#Name of idevsutil binary#
our $idevsutilBinaryPath = $currentDir."/idevsutil";#Path of idevsutil binary#
our $idevsutilCommandLine = undef;
our $periodOperator = ".";
our $pathSeparator = "/";
our $serverAddressOperator = "@";
our $serverNameOperator = "::";
our $operationComplete = "100";
our $errorRedirection = "2>&1";
our $serverName = "home";
our $progressDetailsFilePath = undef;
our $outputErrorfile = $currentDir."/LOGS/outputerror.txt";
our $failedFileName = "failedfiles.txt";
our $retryinfo = "RetryInfo.txt";
our $nonExistsCount = 0;

#Path change required 
our $pidPath = undef;
our $statusFilePath = undef;
our $idevsOutputFile = "output.txt";
our $idevsErrorFile = "error.txt";
our $temp_file = undef;
our $evsTempDirPath = undef;
our $evsTempDir = "/tmp";
our $errorDir = undef;
our $jobRunningDir = undef;
our $notifyPath = undef;
our $data = undef;
#-------

our $fileCountThreadStatus;
our $summary = undef;
our $summaryError = undef;
our $errStr = undef;
our $location = undef;
our $jobType = undef;
our $mail_content = undef;
our $mail_content_head = undef;
our %evsHashOutput = undef;

#*************************************************
our $serverAddress = undef;
our $mkDirFlag = undef;
our @linesStatusFile = undef;
our $outputFilePath = undef;
our $errorFilePath = undef;
our $taskType = undef;
our $status = undef;
our %statusHash = 	(	"COUNT_FILES_INDEX" => undef,
						"SYNC_COUNT_FILES_INDEX" => undef,
						"ERROR_COUNT_FILES" => undef,
						"FAILEDFILES_LISTIDX" => undef,
						"EXIT_FLAG" => undef,
						"PROGRESS_HEADER" => undef,
					);

our $totalFiles = 0;
our $filesConsideredCount = undef;
our $successFiles = 0; #Count of files which have been backed up#
our $syncedFiles = 0; #Count of files which are in sync#
our $failedFilesCount = 0; #Total count of files which could not be backed up/synced #

use constant false => 0;
use constant true => 1;
use constant FILE_COUNT_THREAD_STARTED => 1;
use constant FILE_COUNT_THREAD_COMPLETED => 2;

use constant RELATIVE => "--relative";
use constant NORELATIVE => "--no-relative";

use constant FULLSUCCESS => 1;
use constant PARTIALSUCCESS => 2;

#######################################################################
#Hash to hold the values of arguments to be passed to idevsutil binary#
#######################################################################
my %hashEvsParameters = ( 
			"SERVERADDRESS" => "--getServerAddress",
			"USERNAME" => "--user",
			"PASSWORD" => "--password-file",                       
			"ENCTYPE" => "--enc-type",
			"PVTKEY" => "--pvt-key",                       
			"VALIDATE" => "--validate",
			"CONFIG" => "--config-account",
			"PROXY" => "--proxy",
			"UTF8CMD" => "--utf8-cmd",
			"ENCODE" => "--encode",
			"FROMFILE" => "--files-from",
			"TYPE" => "--type",
			"BWFILE" => "--bw-file",
			"PROPERTIES" => "--properties",
			"XMLOUTPUT" => "--xml-output",
			"GETQUOTA" => "--get-quota",
			"AUTHLIST" => "--auth-list",
			"SPEED" => "--trf-",
			"OUTPUT" => "--o",
			"ERROR" => "--e",
			"PROGRESS" => "--100percent-progress",
			"QUOTAFROMFILE" => "--quota-fromfile",
			"CREATEDIR" => "--create-dir",
			"SEARCH" => "--search",
			"VERSION" => "--version-info",
			"RENAME" => "--rename",
			"OLDPATH" => "--old-path",
			"NEWPATH" => "--new-path",
			"FILE" => "--file",
			"ITEMSTATUS" => "--items-status",
			"ADDPROGRESS" => "--add-progress",
			"TEMP"		=> "--temp"
);

#Errors encountered during backup operation# 
#for which the script should retry the     #
#backup operation                          #
our @ErrorArgumentsRetry = ("idevs error",
                           "io timeout",
                           "Operation timed out",
                           "nodename nor servname provided, or not known",
                           "failed to connect",
                           "Connection refused",
                           "unauthorized user",
                           "connection unexpectedly closed",
                          );
                          
# Errors encountered during backup operation for which the script should not retry the backup operation                         
our @ErrorArgumentsNoRetry = ("No such file or directory",
                             "file name too long",
							 "skipping non-regular file",
							 "Permission Denied",
							 "SFERROR",
                             "IOERROR",
                             "mkstemp"
							);	

# Errors encountered during backup operation for which the script should not retry the backup operation                         
our @ErrorArgumentsExit = (  "encryption verification failed",
                             "some files could not be transferred due to quota over limit",
                             "skipped-over limit",
                             "quota over limit",
                             "account is under maintenance",
                             "account has been cancelled",
                             "account has been expired",
                             "protocol version mismatch",
                             "password mismatch",
                             "out of memory"
                            );
                          
readConfigurationFile();
getConfigHashValue();

our $userName = $hashParameters{USERNAME};
my $proxy = $hashParameters{PROXY};

our $backupHost = $hashParameters{BACKUPLOCATION};
$backupHost = checkLocationInput($backupHost);
	
$backupHost =~ s/^\/+$|^\s+\/+$//g; ## Removing if only "/"(s) to avoid root 

our $restoreHost = $hashParameters{RESTOREFROM};
$restoreHost = checkLocationInput($restoreHost);
if(substr($restoreHost, 0, 1) ne "/") {
	$restoreHost = "/".$restoreHost;
}

our $configEmailAddress = $hashParameters{EMAILADDRESS};
our $bwThrottle = getThrottleVal(); 
our $backupsetFilePathfromConf = $hashParameters{BACKUPSETFILEPATH};
if(substr($backupsetFilePathfromConf, 0, 2) eq "./") {
	$backupsetFilePathfromConf = $currentDir."/".substr($backupsetFilePathfromConf, 2);
} 
our $RestoresetFile = $hashParameters{RESTORESETFILEPATH};
if(substr($RestoresetFile, 0, 2) eq "./") {
	$RestoresetFile = $currentDir."/".substr($RestoresetFile, 2);
} 

our $restoreLocation = $hashParameters{RESTORELOCATION};
$restoreLocation = checkLocationInput($restoreLocation);
#$restoreLocation =~ s/^\/+$|^\s+\/+$//g; ## Removing if only "/"(s) to avoid root

our $ifRetainLogs = $hashParameters{RETAINLOGS};
our $excludeFullPath = $hashParameters{FULLEXCLUDELISTFILEPATH};
our $excludePartialPath = $hashParameters{PARTIALEXCLUDELISTFILEPATH};
our $regexExcludePath = $hashParameters{REGEXEXCLUDEFILEPATH};
our $backupPathType = $hashParameters{BACKUPTYPE};
our $relative = 1;
our $proxyStr = getProxy();
our $defaultBw = undef;
our $defaultEncryptionKey = "DEFAULT";
our $privateEncryptionKey = "PRIVATE";

our $percentageComplete = undef;
our $lineFeedPrint = false;
our $lineFeedPrinted = false;
our $carriageReturn = "\r";
our $percent = "%";
                     
#*******************************************************************************************************
my ($appTypeSupport,$appType) = getAppType();
#Global variables for Downloadable Binary Links

if($appType eq "IDrive") {
	our $EvsBin32 = "https://www.idrive.com/downloads/linux/download-for-linux/idevsutil_linux.zip";
	our $EvsBin64 = "https://www.idrive.com/downloads/linux/download-for-linux/idevsutil_linux64.zip";
	our $EvsQnapBin32_64 = "https://www.idrive.com/downloads/linux/download-options/QNAP_Intel_Atom_64_bit.zip";
	our $EvsSynoBin32_64 = "https://www.idrive.com/downloads/linux/download-options/synology_64bit.zip";
	our $EvsNetgBin32_64 = "https://www.idrive.com/downloads/linux/download-options/Netgear_64bit.zip";
	our $EvsUnvBin	= "https://www.idrive.com/downloads/linux/download-for-linux/idevsutil_linux_universal.zip";
	our $EvsQnapArmBin = "https://www.idrive.com/downloads/linux/download-options/QNAP_ARM.zip";
	our $EvsSynoArmBin = "https://www.idrive.com/downloads/linux/download-options/synology_ARM.zip";
	our $EvsNetgArmBin = "https://www.idrive.com/downloads/linux/download-options/Netgear_ARM.zip";
} elsif($appType eq "IBackup") {
	our $EvsBin32 = "https://www.ibackup.com/online-backup-linux/downloads/download-for-linux/idevsutil_linux.zip";
	our $EvsBin64 = "https://www.ibackup.com/online-backup-linux/downloads/download-for-linux/idevsutil_linux64.zip";
	our $EvsSynoArmBin = "https://www.ibackup.com/online-backup-linux/downloads/download-options/synology_ARM.zip";
	our $EvsSynoBin32_64 = "https://www.ibackup.com/online-backup-linux/downloads/download-options/synology_64bit";
	our $EvsQnapArmBin = "https://www.ibackup.com/online-backup-linux/downloads/download-options/QNAP_ARM.zip";
	our $EvsQnapBin32_64 = "https://www.ibackup.com/online-backup-linux/downloads/download-options/QNAP_Intel_Atom_64_bit.zip";
	our $EvsNetgArmBin = "https://www.ibackup.com/online-backup-linux/downloads/download-options/Netgear_ARM.zip";
	our $EvsNetgBin32_64 = "https://www.ibackup.com/online-backup-linux/downloads/download-options/Netgear_64bit.zip";
	our $EvsUnvBin = "https://www.ibackup.com/online-backup-linux/downloads/download-for-linux/idevsutil_linux_universal.zip";
	#Solaris: https://www.ibackup.com/online-backup-linux/downloads/download-options/idevsutil_SOLARIS_x86.zip
}

#CGI Links to verify Account
our $IDriveAccVrfLink = "https://www.idrive.com/cgi-bin/get_idrive_evs_details_xml_ip.cgi?";
our $IBackupAccVrfLink = "https://www1.ibackup.com/cgi-bin/get_ibwin_evs_details_xml_ip.cgi?";
#our $IDriveAccVrfLink = "http://www.idrive.com/cgi-bin/get_idrive_evs_details_xml_ip.cgi?";
#our $IBackupAccVrfLink = "http://www1.ibackup.com/cgi-bin/get_ibwin_evs_details_xml_ip.cgi?";
#*******************************************************************************************************/

if(${ARGV[0]} eq "Backup" or ${ARGV[0]} eq "Restore") {
	if($ARGV[1] ne ""){
		$userName = $ARGV[1] ;
	}
}

loadUserData();

#********************************************************************************************************
# Subroutine Name         : loadUserData.
# Objective               : loading Path and creating files/folders based on username.
# Added By                : Dhritikana
#********************************************************************************************************/
sub loadUserData {
	our $currentDirforCmd = quotemeta($currentDir);
	our $usrProfilePath = "$currentDir/user_profile";
	our $pwdPath = "$usrProfilePath/$userName/.IDPWD";
	our $enPwdPath = "$usrProfilePath/$userName/.IDENPWD";
	our $pvtPath = "$usrProfilePath/$userName/.IDPVT";
	our $utf8File = "$usrProfilePath/$userName/.utf8File.txt";
	our $serverfile = "$usrProfilePath/$userName/.serverAddress.txt";
	our $bwPath = "$usrProfilePath/$userName/.bw.txt";
	our $usrProfileDir = "$usrProfilePath/$userName";
	our $cacheDir = "$currentDir/.cache";
	our $userTxt = "$cacheDir/user.txt";
	
	chmod 0777, $usrProfilePath;

	if( -e $serverfile) {
		open FILE, "<", $serverfile or (print $tHandle $lineFeed.CONST->{'FileOpnErr'}.$serverfile." , Reason:$! $lineFeed" and die);
		$serverAddress = <FILE>;
		chomp($serverAddress);
		close FILE;
	}

	my $traceDir = "$usrProfileDir/.trace";
	our $traceFileName = "$traceDir/traceLog.txt";
	if(-d $traceDir) {
	}
	elsif($userName ne "<your IDrive account user name>"){ ###Need review
		mkpath($traceDir); # Need Review
		chmod 0777, $traceDir;
	}
	if((-s $traceFileName) >= (2*1024*1024)) {
		my $date = localtime();
		my $tempTrace = $traceFileName . "_" . $date;
		move($traceFileName, $tempTrace);
	}
	open($tHandle, ">> $traceFileName");# or print "DEBUG: trace open $!\n";	
	chmod 0777, $traceFileName;
}
           
#********************************************************************************************************
# Subroutine Name         : messgae.
# Objective               : For debugging.
# Added By                : Dhritikana
#********************************************************************************************************/
sub message {
	autoflush $tHandle;
	my $msg = $_[0];
	print $tHandle $_[0].$lineFeed;
}

#********************************************************************************************************
# Subroutine Name         : addtionalErrorInfo.
# Objective               : Logs error info into temporay error text file which is displayed in Log page.
# Added By                : Basavaraj Bennur. [modified by dhriti]
#********************************************************************************************************/
sub addtionalErrorInfo()
{	
	my $TmpErrorFilePath = ${$_[0]};
	chmod 0777, $TmpErrorFilePath;
	
	if(!open(FHERR, ">>",$TmpErrorFilePath)){
		print $tHandle "Could not open file TmpErrorFilePath in additionalErrorInfo: $TmpErrorFilePath, Reason:$!\n"; 
		print $tHandle "${$_[1]}\n"; 
		return;
	}
	print FHERR "${$_[1]}\n";	
	close FHERR;
}

#****************************************************************************************************
# Subroutine Name         : createCache.
# Objective               : Create cache Folder and related files if not. 
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub createCache {
	if( !-d $cacheDir) {
		my $res = mkdir $cacheDir;
		if($res ne 1) {
			print CONST->{'MkDirErr'}.$cacheDir."$res $!".$lineFeed;
			print $tHandle CONST->{'MkDirErr'}.$cacheDir."$res $!".$lineFeed;
			exit 1;
		}
		chmod 0777, $cacheDir;
	}

	#if( !-e $userTxt or !-f $userTxt or ${$_[0]} eq "") {
		unless( open USERFILE, ">", $userTxt ) {
			die " Unable to open $userTxt. Reason: $!\n";
			exit 1;
		}
		chmod 0777, $userTxt;
		print USERFILE $userName;
		close USERFILE;
	#} 
}

#****************************************************************************************************
# Subroutine Name         : getCurrentUser.
# Objective               : Get previous logged in username from user.txt. 
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub getCurrentUser {
	if( !-d $cacheDir) {
		return;
	}
	
	if( -e $userTxt and -f $userTxt) {
		unless( open USERFILE, "<", $userTxt ) {
			print $tHandle " Unable to open $userTxt\n";
			return;
		}
		my $PrevUser = <USERFILE>;
		chomp($PrevUser);
		close USERFILE;
		return $PrevUser;
	} 
}

#****************************************************************************************************
# Subroutine Name         : checkLocationInput.
# Objective               : Checking if user give backup/restore location as root. 
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub checkLocationInput {
	my $input = $_[0];
	
	if($input eq "") {
		$input = `hostname`;
		chomp($input);
		return $input;
	}

	$input =~ s/^\s+\/+|^\/+/\//g; ## Replacing starting "/"s with one "/"
	$input =~ s/^\s+//g; ## Removing Blank spaces
		
	if(length($input) <= 0) {
			print $whiteSpace.CONST->{'InvLocInput'}.$whiteSpace.${$_[0]}.$lineFeed;
			print $tHandle $whiteSpace.CONST->{'InvLocInput'}.$whiteSpace.${$_[0]}.$lineFeed;
			exit 1;
	} 
	
	
	return $input;
}

#****************************************************************************************************
# Subroutine Name         : checkEncType.
# Objective               : This function loads encType based on configuartion and user's actual profile.
# Added By				  : Dhritikana
#*****************************************************************************************************/
sub checkEncType {
	my $flagToCheckSchdule = $_[0];
	my $encKeyType = $defaultEncryptionKey;

	if(!$flagToCheckSchdule) {
		if(defined $hashParameters{PVTKEY} && $hashParameters{PVTKEY} ne "") {
			$encKeyType = $privateEncryptionKey;
		}
	}
	elsif($flagToCheckSchdule eq 1) {
		if(-e $pvtPath) {  
			$encKeyType = $privateEncryptionKey;
		} 
	}
	return $encKeyType;
}
#****************************************************************************************************
# Subroutine Name         : getThrottleVal.
# Objective               : Verify bandwidth throttle value from CONFIGURATION File 
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub getThrottleVal {
	my $bwVal = $hashParameters{BWTHROTTLE}; 
	if(defined $bwVal and $bwVal =~ m/^\d+$/ and 0 <= $bwVal and 100 > $bwVal) {
	} else {
		$defaultBw = 1;
		$bwVal = 100;
	}
	return $bwVal;
}


#****************************************************************************************************
# Subroutine Name         : verifyAndLoadServerAddr.
# Objective               : Verify if Server file exists and Get Server Address from server file 
#							and verify the IP. In case file doesn't exist excute getServeraddress.
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub verifyAndLoadServerAddr {
	my $fetchAddress = 0;
	if(!-e $serverfile) {
		#Excute Get Server Addr 
		getServerAddr();
		$fetchAddress = 1;
	}
	
	open FILE, "<", $serverfile or (print $tHandle $lineFeed.CONST->{'FileOpnErr'}.$serverfile." , Reason:$! $lineFeed" and die);
	my $TmpserverAddress = <FILE>;
	chomp($TmpserverAddress);
	
	#verify if IP is valid
	if($TmpserverAddress =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ 
	&& (0 le $1 && $1 le 255  && 0 le $2 && $2 le 255 && 0 le $3 && $3 le 255  && 0 le $4 && $4 le 255)) 
	{
		return $TmpserverAddress;
	} elsif(!$fetchAddress) 
	{
			getServerAddr();
	}
}

#****************************************************************************************************
# Subroutine Name         : createUpdateBWFile.
# Objective               : Create or update bandwidth throttle value file(.bw.txt). 
# Added By                : Avinash Kumar.
# Modified By		    	: Dhritikana
#*****************************************************************************************************/
sub createUpdateBWFile()
{
	open BWFH, ">", $bwPath or (print $tHandle $lineFeed.CONST->{'FileOpnErr'}.$bwPath." , Reason:$! $lineFeed" and die);
	chmod 0777, $bwPath;
	print BWFH $bwThrottle;
	close BWFH;
}

#****************************************************************************************************
# Subroutine Name         : getAppType.
# Objective               : Get application type like ibackup/IDrive. 
# Added By                : Avinash Kumar.
#*****************************************************************************************************/
sub getAppType
{
	$appTypeSupport = "idrive";
	$appType = "IDrive";
	return ($appTypeSupport,$appType);
}

#****************************************************************************************************
# Subroutine Name         : checkBinaryExists.
# Objective               : This subroutine checks for the existence of idevsutil binary in the
#							current directory and also if the binary has executable permission.
# Added By                : Dhritikana
#*****************************************************************************************************/
sub checkBinaryExists()
{
	my $errMsg = "";	
  	if(!-e $idevsutilBinaryPath) {
			$errMsg = CONST->{'EvsMissingErr'}.$lineFeed;
  	} elsif(!-x $idevsutilBinaryPath) {
			$errMsg = CONST->{'EvsPermissionErr'}.$lineFeed;
  	}
  	return $errMsg;
}

#****************************************************************************************************
# Subroutine Name         : createPwdFile.
# Objective               : Create password or private encrypted file.
# Added By                : Avinash Kumar.
#*****************************************************************************************************/
sub createEncodeFile()
{
	my $data = $_[0];
	my $path = $_[1];
	my $utfFile = "";
	$utfFile = getUtf8File($data, $path);
	chomp($utfFile);
	
	$idevsutilCommandLine = $idevsutilBinaryPath.
			        $whiteSpace.$hashEvsParameters{UTF8CMD}.$assignmentOperator."'".$utfFile."'";

	my $commandOutput = `$idevsutilCommandLine`;
	print $tHandle $lineFeed.CONST->{'CrtEncFile'}.$whiteSpace.$commandOutput.$lineFeed;
	unlink $utfFile;
}

#****************************************************************
# Subroutine Name         : createEncodeSecondaryFile           *
# Objective               : Create Secondary Encoded password.  *
# Added By                : Dhritikana.                         *
#****************************************************************
sub createEncodeSecondaryFile()
{
	my $pdata = $_[0];
	my $path = $_[1];
	my $udata = $_[2];
	
	my $len = length($udata); 
	my $pwd = pack( "u", "$pdata"); chomp($pwd);
	$pwd = $len."_".$pwd;
	
	open FILE, ">", "$enPwdPath" or (print $tHandle $lineFeed.CONST->{'FileCrtErr'}.$enPwdPath."failed reason: $! $lineFeed" and die);
	chmod 0777, $enPwdPath;
	print FILE $pwd;
	close(FILE);
}

#***********************************************************************
# Subroutine Name         : getPdata   
# Objective               : Get Pdata in order to send Mail notification 
# Added By                : Dhritikana.
#***********************************************************************
sub getPdata()
{
	my $udata = $_[0];
	
	chmod 0777, $enPwdPath;
	open FILE, "<", "$enPwdPath" or (print $tHandle $lineFeed.CONST->{'FileOpnErr'}.$enPwdPath." failed reason:$! $lineFeed" and die);
	my $enPdata = <FILE>; chomp($enPdata);
	close(FILE);
	
	my $len = length($udata);
	my ($a, $b) = split(/\_/, $enPdata, 2); 
	my $pdata = unpack( "u", "$b");
	if($len eq $a) {
		return $pdata;
	}
}

#****************************************************************************************************
# Subroutine Name         : getUtf8File.
# Objective               : Create utf8 file.
# Added By                : Avinash Kumar.
#*****************************************************************************************************/

sub getUtf8File()
{
	my ($getVal, $encPath) = @_;
	#create utf8 file.
 	open FILE, ">", "$usrProfileDir/utf8.txt" or (print $tHandle $lineFeed. $lineFeed.CONST->{'FileOpnErr'}."utf8.txt. failed reason:$! $lineFeed" and die);
  	print FILE "--string-encode=$getVal\n",
			"--out-file=$encPath\n";
	
  	close(FILE);
  	chmod 0777, "$usrProfileDir/utf8.txt";
	return "$usrProfileDir/utf8.txt";	
}

#****************************************************************************************************
# Subroutine Name		: updateServerAddr.
# Objective				: Construction of get-server address evs command and execution.
#			    			Parse the output and update same in Account Setting File.
# Added By				: Avinash Kumar.
# Modified By			: Dhritikana  
#*****************************************************************************************************/
sub getServerAddr()
{
	my $getServerUtfFile = undef;
	my $proxyString = undef;
	if(!($_[0]) && $_[0] ne "modproxy"){
		$getServerUtfFile = getOperationFile($getServerAddressOp);
	} else {
		$proxyString = $_[1];
		$getServerUtfFile =	getOperationFile($getServerAddressOp, "modProxy", $proxyString);
	}
	$getServerUtfFile =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$getServerUtfFile."'".$whiteSpace.$errorRedirection.$lineFeed;

	my $commandOutput = `$idevsutilCommandLine`;
	unlink($getServerUtfFile);
	
	parseXMLOutput(\$commandOutput);
	my $addrMessage = $evsHashOutput{'message'};
	$serverAddress = $evsHashOutput{'cmdUtilityServerIP'};
	my $desc = $evsHashOutput{'desc'};
	
	print $tHandle $lineFeed.CONST->{'GetServAddr'}.$commandOutput.$lineFeed;
	#print $lineFeed."----$addrMessage---------".$desc."----------".$lineFeed;
	
	###DOUBT: for connect fail msg evs output is not in xml format ! and "ERROR" category
	if($commandOutput =~ /reason\: connect\(\) failed/) {
		print $lineFeed.$whiteSpace.CONST->{'ProxyErr'}.$lineFeed.$whiteSpace;
		if($mkDirFlag) {
			rmtree($userName);
		}
		exit();
	}
	
	if($commandOutput =~ /idevs error/ && $commandOutput !~ /Invalid username or Password|too short/) {
		print $tHandle $lineFeed.$commandOutput.$lineFeed;
	}
	
	if($addrMessage =~ /ERROR/) {
	#if($commandOutput =~ /Invalid username or Password|too short/) {
		print $lineFeed.$whiteSpace.$desc.$lineFeed.$whiteSpace;
		if($mkDirFlag) {
			rmtree($usrProfileDir);
			unlink $pwdPath; ###Need Check 
			unlink $enPwdPath;
		}
		exit();
	}

	if(0 < length($serverAddress)) {
		open FILE, ">", $serverfile or (print $tHandle $lineFeed.CONST->{'FileOpnErr'}."$serverfile for getServerAddress, Reason:$! $lineFeed" and die);
		print FILE $serverAddress;
		close FILE;
		chmod 0777, $serverfile;
	}
	else {
		print $tHandle $lineFeed.CONST->{'GetSrvAdrErr'}.$lineFeed; 
		#unlink($pwdPath);
		#unlink($enPwdPath);
		exit;
	}
} 

#**********************************************************************************
# Subroutine Name         : readConfigurationFile
# Objective               : This subroutine reads the entire Configuration File
# Added By                : 
#**********************************************************************************
sub readConfigurationFile
{
	chmod 0777, $confFilePath;
	open CONF_FILE, "<", $confFilePath or (print $tHandle $lineFeed.CONST->{'ConfMissingErr'}." reason :$! $lineFeed" and die);
	@linesConfFile = <CONF_FILE>;  
	close CONF_FILE;
}

#*******************************************************************************************************************
# Subroutine Name         : getParameterValue
# Objective               : fetches the value of individual parameters which are specified in the configuration file
# Added By                : 
#********************************************************************************************************************
sub getParameterValue
{
	foreach my $line (@linesConfFile) { 
		if($line =~ m/${$_[0]}/) {
			my @keyValuePair = split /= /, $line;
			${$_[1]} = $keyValuePair[1];
			chomp ${$_[1]};
			
			${$_[1]} =~ s/^\s+//;
			${$_[1]} =~ s/\s+$//;
			
			last;
		}
	}
}

#*******************************************************************************************************************
# Subroutine Name         : putParameterValue
# Objective               : edits the value of individual parameters which are specified in the configuration file.
# Added By                : Dhritikana
#********************************************************************************************************************
sub putParameterValue
{
	my $matchFlag = 0;
	readConfigurationFile();
	open CONF_FILE, ">", $confFilePath or (print $tHandle $lineFeed.CONST->{'ConfMissingErr'}." reason :$! $lineFeed" and die);
	foreach my $line (@linesConfFile) {
		if($matchFlag == 0 && $line =~ /${$_[0]}/) {
			$line = "${$_[0]} = ${$_[1]}\n";
			$matchFlag = 1;
		}
		print CONF_FILE $line;
	}
	close CONF_FILE;
}

#*******************************************************************************************************************
# Subroutine Name         : getConfigHashValue
# Objective               : fetches the value of individual parameters which are specified in the configuration file
# Added By                : Dhritikana
#********************************************************************************************************************
sub getConfigHashValue
{
	foreach my $line (@linesConfFile) { 
			my @keyValuePair = split /= /, $line;
			chomp $keyValuePair[0];
			
			$keyValuePair[0] =~ s/^\s+//;
			$keyValuePair[0] =~ s/\s+$//;
			
			$hashParameters{$keyValuePair[0]} = $keyValuePair[1];
			$hashParameters{$keyValuePair[0]} =~ s/^\s+//;
			$hashParameters{$keyValuePair[0]} =~ s/\s+$//;
	}
}

#****************************************************************************************************
# Subroutine Name         : readStatusFile.
# Objective               : reads the status file 
# Added By                : Deepak Chaurasia
#*****************************************************************************************************/
sub readStatusFile()
{
	if(-f $statusFilePath and -s $statusFilePath ) {
		chmod 0777, $statusFilePath;
		if(open(STATUS_FILE, "< $statusFilePath")) { 
			@linesStatusFile = <STATUS_FILE>;
			close STATUS_FILE;
			if($#linesStatusFile >= 0) {
				foreach my $line (@linesStatusFile) { 
					my @keyValuePair = split /=/, $line;
					chomp @keyValuePair;
					s/^\s+|\s+$//g for (@keyValuePair);
					$keyValuePair[1] = 0 if(!$keyValuePair[1]);
					$statusHash{$keyValuePair[0]} = $keyValuePair[1];
				}
			}
		}
	} 
	else {
			print $tHandle "Failed to open Status file $statusFilePath, Reason:$! $lineFeed"; 
	}
}


#****************************************************************************************************
# Subroutine Name         : getParameterValueFromStatusFile.
# Objective               : Fetches the value of individual parameters which are specified in the 
#                           Account Settings file.
# Added By                : Arnab Gupta.
# Modified By			  : Deepak Chaurasia, Dhritikana
#*****************************************************************************************************/
sub getParameterValueFromStatusFile()
{
	if($#linesStatusFile le 1) {
		readStatusFile();
	}

	if($#linesStatusFile >= 0){
		return $statusHash{$_[0]};
	} else {
		return 0;
	}
}

#****************************************************************************************************
# Subroutine Name         : putParameterValueInStatusFile.
# Objective               : Changes the content of STATUS FILE as per values passed
# Added By                : Dhritikana
#*****************************************************************************************************/
sub putParameterValueInStatusFile()
{
	open STAT_FILE, ">", $statusFilePath or (print $tHandle $lineFeed.CONST->{'StatMissingErr'}." reason :$! $lineFeed" and die);
	foreach my $keys(keys %statusHash) {
		print STAT_FILE "$keys = $statusHash{$keys}\n";
	}
	close STAT_FILE;
	chmod 0777, $statusFilePath;
	undef @linesStatusFile;
}

#*******************************************************************************************************************
# Subroutine Name         : getOperationFile
# Objective               : Create utf8 file for EVS command respective to operation type(backup/restore/validate...)
# Added By                : Avinash Kumar.
#********************************************************************************************************************
sub getOperationFile()
{
	my $opType = "";
	my $utfFile = "";
	my $utfValidate = "";
	my $utfPath = $jobRunningDir."/utf8.txt";
	my $proxyString = getProxy();
	#my $serverAddress = "";
	my $serverAddressOperator = "@";
	my $serverName = "home";
	my $serverNameOperator = "::";
	my $encryptionType = "";

	my $operationType = $_[0];


	if($operationType == $validateOp)
        {       
			$utfPath = $usrProfileDir."/utf.txt";
			open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for validate, Reason:$!" and die);
                $utfFile = $hashEvsParameters{VALIDATE}.$lineFeed.
                           $hashEvsParameters{USERNAME}.$assignmentOperator.$userName.$lineFeed.
                           $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
                           $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
                           $hashEvsParameters{ENCODE}.$lineFeed;
                           #$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed;
        }
	elsif($operationType == $getServerAddressOp)
        {
				$utfPath = $usrProfileDir."/utf.txt";
                open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for getServerAddress, Reason:$!" and die);
                $utfFile = $hashEvsParameters{SERVERADDRESS}.$lineFeed.
                           $userName.$lineFeed.
                           $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed;
							if(defined($_[1]) && $_[1] eq "modProxy") {
								$proxyString = $_[2];
							}

				$utfFile .=	$hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
							$hashEvsParameters{ENCODE}.$lineFeed.
							$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed;
        }
	elsif($operationType == $configOp)
        {
				$utfPath = $usrProfileDir."/utf.txt";
                open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for config, Reason:$!" and die);
                $utfFile = $hashEvsParameters{CONFIG}.$lineFeed.
                           $hashEvsParameters{USERNAME}.$assignmentOperator.$userName.$lineFeed.
                           $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed;
                if("PRIVATE" eq $_[1]){
                        $utfFile .= $hashEvsParameters{ENCTYPE}.$assignmentOperator.$privateEncryptionKey.$lineFeed.
                                    $hashEvsParameters{PVTKEY}.$assignmentOperator.$pvtPath.$lineFeed;
                }
                else{
                        $utfFile .= $hashEvsParameters{ENCTYPE}.$assignmentOperator.$defaultEncryptionKey.$lineFeed;
                }
                if(defined($_[2]) && $_[2] eq "modProxy") {
					$proxyString = $_[3];
				}
                $utfFile .= $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
                            $hashEvsParameters{ENCODE}.$lineFeed;
        }
	elsif($operationType == $createDirOp)
        {
				$utfPath = $usrProfileDir."/utf.txt";
                #tie my @servAddress, 'Tie::File', "$currentDir/$userName/.serverAddress.txt" or (print $tHandle "Can not tie to $serverfile, Reason:$!");
                open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for createDir, Reason:$!" and die);
                $utfFile = $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed;
                if($_[1] eq "PRIVATE"){
                        $utfFile .= $hashEvsParameters{ENCTYPE}.$assignmentOperator.$privateEncryptionKey.$lineFeed.
                                    $hashEvsParameters{PVTKEY}.$assignmentOperator.$pvtPath.$lineFeed;
                }
                if(defined($_[2]) && $_[2] eq "modProxy") {
					$proxyString = $_[3];
				}
				
				$utfFile .= $hashEvsParameters{ENCODE}.$lineFeed.
							$hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
							$hashEvsParameters{CREATEDIR}.$assignmentOperator.$backupHost.$lineFeed.
							$userName.$serverAddressOperator.
							$serverAddress.$serverNameOperator.
							$serverName.$lineFeed;
        }
	elsif($operationType == $backupOp) {
		my $BackupsetFile = $_[1];
		my $relativeAsPerOperation = $_[2];
		my $source = $_[3];
		my $encryptionType = $_[4];

		#open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for backup, Reason:$!" and return 0);
		open UTF8FILE, ">", $utfPath or ($errStr = CONST->{'FileOpnErr'}.$utfPath." for backup, Reason:$!" and return 0);
		$utfFile = $hashEvsParameters{FROMFILE}.$assignmentOperator.$BackupsetFile.$lineFeed.
   			   $hashEvsParameters{BWFILE}.$assignmentOperator.$bwPath.$lineFeed.
   			   $hashEvsParameters{TYPE}.$lineFeed.
   			   $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed;
		if($encryptionType =~ m/^$privateEncryptionKey$/i) {
			$utfFile .= $hashEvsParameters{PVTKEY}.$assignmentOperator.$pvtPath.$lineFeed;
		}
		$utfFile .= $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
					$hashEvsParameters{ENCODE}.$lineFeed.
					$relativeAsPerOperation.$lineFeed.
					$hashEvsParameters{TEMP}.$assignmentOperator.$evsTempDir.$lineFeed.
					$hashEvsParameters{OUTPUT}.$assignmentOperator.$idevsOutputFile.$lineFeed.
					$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
					$hashEvsParameters{ADDPROGRESS}.$lineFeed.
					$source.$lineFeed.
					$userName.$serverAddressOperator.
					$serverAddress.$serverNameOperator.
					$serverName.$pathSeparator.$backupHost.$pathSeparator.$lineFeed;
	}
	elsif($operationType == $restoreOp) {
		my $RestoresetFile = $_[1];
		my $relativeAsPerOperation = $_[2];
		my $source = $_[3];
		my $encryptionType = $_[4];
		
	   open UTF8FILE, ">", $utfPath or ($errStr = CONST->{'FileOpnErr'}.$utfPath." for restore, Reason:$!" and return 0);
	   $utfFile = $hashEvsParameters{FROMFILE}.$assignmentOperator.$RestoresetFile.$lineFeed.
				  $hashEvsParameters{TYPE}.$lineFeed.
				  $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed;
	   if($encryptionType =~ m/^$privateEncryptionKey$/i) {
				$utfFile .= $hashEvsParameters{PVTKEY}.$assignmentOperator.$pvtPath.$lineFeed;
	   }
		$utfFile .= $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
					$hashEvsParameters{ENCODE}.$lineFeed.
					$relativeAsPerOperation.$lineFeed.
					$hashEvsParameters{TEMP}.$assignmentOperator.$evsTempDir.$lineFeed.
					$hashEvsParameters{OUTPUT}.$assignmentOperator.$idevsOutputFile.$lineFeed.
					$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
					$hashEvsParameters{ADDPROGRESS}.$lineFeed.
					$userName.$serverAddressOperator.
					$serverAddress.$serverNameOperator.
					$serverName.$source.$lineFeed.
					$restoreLocation.$lineFeed;
	}
	elsif($operationType == $propertiesOp) {
		if(defined($_[1]) && $_[1] eq "modProxy") {
			$proxyString = $_[2];
		}
		$utfPath = $usrProfileDir."/utf.txt";
		open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for properties, Reason:$!" and die);
		$utfFile =	$hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
					$hashEvsParameters{PROPERTIES}.$lineFeed.
					$hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
					$hashEvsParameters{ENCODE}.$lineFeed;
		if(!defined($_[1]) && $_[1] ne "modProxy") {
			$utfFile .=	$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed;
		}
		$utfFile .= $userName.$serverAddressOperator.
					$serverAddress.$serverNameOperator.
					$serverName.$pathSeparator.$restoreHost;
	}
	elsif($operationType == $versionOp) {
			my $filePath = $_[1];
			$utfPath = $usrProfileDir."/utf.txt";
			open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for properties, Reason:$!" and die);
			$utfFile = $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
				   $hashEvsParameters{VERSION}.$lineFeed.
				   $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
			   	   $hashEvsParameters{ENCODE}.$lineFeed.
				   $hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
			   	   $userName.$serverAddressOperator.
			   	   $serverAddress.$serverNameOperator.
			   	   $serverName.$pathSeparator.$filePath;
	} elsif($operationType == $renameOp) {
			$utfPath = $usrProfileDir."/utf.txt";
			my $oldPath = $_[2];
			my $newPath = $_[3];
			if(defined($_[4]) && $_[4] eq "modProxy") {
					$proxyString = $_[5];
			}
			open UTF8FILE, ">", $utfPath or (print $tHandle CONST->{'FileOpnErr'}.$utfPath." for properties, Reason:$!" and die);
			$utfFile = $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
				   $hashEvsParameters{RENAME}.$lineFeed.
				   $hashEvsParameters{OLDPATH}.$assignmentOperator.$oldPath.$lineFeed.
				   $hashEvsParameters{NEWPATH}.$assignmentOperator.$newPath.$lineFeed;
		   if("PRIVATE" eq $_[1]){
                        $utfFile .= $hashEvsParameters{PVTKEY}.$assignmentOperator.$pvtPath.$lineFeed;
			}
			$utfFile .=	   $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
			   	   $hashEvsParameters{ENCODE}.$lineFeed.
				   $hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
			   	   $userName.$serverAddressOperator.
			   	   $serverAddress.$serverNameOperator.
			   	   $serverName.$pathSeparator;
	}
	elsif($operationType == $authListOp)
	{
			if(defined($_[1]) && $_[1] eq "modProxy") {
						$proxyString = $_[2];
			}
			open UTF8FILE, ">", $utfPath or (print $tHandle "Could not open file $utfPath for auth list, Reason:$!" and die);
			$utfFile = $hashEvsParameters{AUTHLIST}.$lineFeed.
				   $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
				   $hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
				   $hashEvsParameters{ENCODE}.$lineFeed.
				   #$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
				   $userName.$serverAddressOperator.
				   $serverAddress.$serverNameOperator.
				   $serverName.$pathSeparator;
	}
	elsif($operationType == $searchOp) {
		my $searchUtfPath = "$jobRunningDir/searchUtf8.txt";
		open UTF8FILE, ">", $searchUtfPath or ($errStr = "Could not open file $utfFile for search, Reason:$!" and return 0);
		$utfFile = $hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
		$hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
		$hashEvsParameters{ENCODE}.$lineFeed.
		$hashEvsParameters{OUTPUT}.$assignmentOperator.$jobRunningDir."/Search/output.txt".$lineFeed.
		$hashEvsParameters{ERROR}.$assignmentOperator.$jobRunningDir."/Search/error.txt".$lineFeed.
		#$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
		$hashEvsParameters{SEARCH}.$lineFeed.
		$hashEvsParameters{FILE}.$lineFeed.
		$userName.$serverAddressOperator.
		$serverAddress.$serverNameOperator.
		$serverName.$_[1].$pathSeparator.$lineFeed;
		print UTF8FILE $utfFile;
		close UTF8FILE;
		print $tHandle $searchUtfPath;
		print $tHandle $utfFile;
		chmod 0777, $searchUtfPath;
		return $searchUtfPath;
	}
	elsif($operationType == $itemStatOp) {
		open UTF8FILE, ">", $utfPath or ($errStr = "Could not open file $utfFile for search, Reason:$!" and return 0);
		$utfFile = $hashEvsParameters{FROMFILE}.$assignmentOperator.$_[1].$lineFeed.
		$hashEvsParameters{PASSWORD}.$assignmentOperator.$pwdPath.$lineFeed.
		$hashEvsParameters{PROXY}.$assignmentOperator.$proxyString.$lineFeed.
		$hashEvsParameters{TEMP}.$assignmentOperator.$jobRunningDir.$lineFeed.
		$hashEvsParameters{ENCODE}.$lineFeed.
		#$hashEvsParameters{ERROR}.$assignmentOperator.$idevsErrorFile.$lineFeed.
		$hashEvsParameters{ITEMSTATUS}.$lineFeed.
		$userName.$serverAddressOperator.
		$serverAddress.$serverNameOperator.
		$serverName.$pathSeparator.$lineFeed;
	}
	else {
			print $tHandle CONST->{'InvalidOp'};
	}
	
	print UTF8FILE $utfFile;
	close UTF8FILE;
	print $tHandle $utfFile;
	chmod 0777, $utfPath;
	return $utfPath;
}

#****************************************************************************************************
# Subroutine Name         : parseXMLOutput.
# Objective               : Parse evs command output and load the elements and values to an hash.
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub parseXMLOutput
{
	${$_[0]} =~ s/^$//;
	if(defined ${$_[0]} and ${$_[0]} ne "") {
		my $evsOutput = ${$_[0]};
		$evsOutput  =~ s/\n\<(tree )?//;
		#$evsOutput  =~ s/^\<tree\ //;
		#$evsOutput =~ s/\"\/\>$//;
		$evsOutput =~ s/\"\/\>//;
		my @evsArrLine = split(/\" /, $evsOutput);
		foreach(@evsArrLine) {
			my ($key,$value) = split(/\="/, $_);
			$evsHashOutput{$key} = $value;
		}
	}
}

sub getProxy
{
	my $proxyStr = "";
	my($proxyIP) = $proxy =~ /@(.*)\:/; 
	if($proxyIP ne ""){
		return $proxy;
	}
	return $proxyStr;
}
   

#****************************************************************************************************
# Subroutine Name         : getFinalMailAddrList
# Objective               : To get valid multiple mail address list
# Added By                : Dhritikana
#*****************************************************************************************************
sub getFinalMailAddrList
{
	my $count = 0; 
	my $finalAddrList = undef; 
	
	if($configEmailAddress ne "") {
		my @addrList = split(/\,|\;/, $configEmailAddress);
		foreach my $addr (@addrList) {
			if(validEmailAddress($addr)) {
				$count++;
				$finalAddrList .= "$addr,";
			} else
			{
				print CONST->{'SendMailErr'}.CONST->{'InvalidEmail'}." $addr $lineFeed";
				print $tHandle CONST->{'SendMailErr'}.CONST->{'InvalidEmail'}." $addr $lineFeed";
				open ERRORFILE, ">>", $errorFilePath;
				chmod 0777, $errorFilePath;
				autoflush ERRORFILE;
				
				print ERRORFILE CONST->{'SendMailErr'}.CONST->{'InvalidEmail'}." $addr $lineFeed";
				close ERRORFILE;
			}
		}
		if($count > 0) {
			return $finalAddrList;
		} 
		else {
			print $tHandle CONST->{'SendMailErr'}.CONST->{'EmlIdMissing'};
			return "NULL";
		}
	}
}

#*******************************************************************************************************************
# Subroutine Name         : sendMail
# Objective               : sends a mail to the user in ase of successful/canceled/ failed scheduled backup/restore.
# Added By                : Dhritikana
#********************************************************************************************************************
sub sendMail()
{
	if($taskType eq "Manual") {
		return;
	}

	my $finalAddrList = getFinalMailAddrList($configEmailAddress);
	if($finalAddrList eq "NULL") {
		return;
	} 	
	
	my $sender = "support\@$appTypeSupport.com";
	my $content = "";
	my $subjectLine = $_[0];
	
	$content = "Dear $appType User, \n\n";	
	$content .= "Ref : Username - $userName \n";
	$content .= $mail_content_head;
	$content .= $mail_content;

	if($jobType eq "Backup" && $status eq "SUCCESS*") {	
		$content .= "\n Note: Successful $jobType* denotes \'mostly success\' or \'majority of files are successfully backed up\' \n";
	} elsif($jobType eq "Backup" && $status eq "SUCCESS*") {	
		$content .= "\n Note: Successful $jobType* denotes \'mostly success\' or \'majority of files are successfully restored\' \n";
	}

	$content .= "\n\nRegards, \n";
	$content .= "$appType Support.\n";
	$content .= "$versionNumber";
	
	my $pData = &getPdata("$userName");
	
	#URL DATA ENCODING#
	foreach ($userName,$pData,$finalAddrList,$subjectLine,$content) {
		$_ =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	}
	$notifyPath = 'https://webdav.ibackup.com/cgi-bin/Notify_email_ibl';
	$data = 'username='.$userName.'&password='.$pData.'&to_email='.$finalAddrList.'&subject='.$subjectLine.'&content='.$content;
	#`curl -d '$data' '$PATH' &>/dev/nul` or print $tHandle "$linefeed Couldn't send mail. $linefeed";
	my $curlCmd = formSendMailCurlcmd();
	`$curlCmd`;
}

#*****************************************************************************************************
# Subroutine Name         : formSendMailCurlcmd
# Objective               : forms curl command to send mail based on proxy settings
# Added By                : Dhritikana
#*****************************************************************************************************
sub formSendMailCurlcmd {
	my $cmd = undef;
	if($proxyStr) {
		my ($uNPword, $ipPort) = split(/\@/, $proxyStr);
		my @UnP = split(/\:/, $uNPword);
		if($UnP[0] ne "") {
			foreach ($UnP[0], $UnP[1]) {
				$_ =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
			}
			$uNPword = join ":", @UnP;
			$cmd = "curl -x http://$uNPword\@$ipPort -d '$data' '$notifyPath' 2>tracelog.txt 1>>tracelog.txt";
		} else {
			$cmd = "curl -x http://$ipPort -d '$data' '$notifyPath' 2>tracelog.txt 1>>tracelog.txt";
		}
	} else {			
		$cmd = "curl -d '$data' '$notifyPath' 2>tracelog.txt 1>>tracelog.txt";
	}
	return $cmd;	
}

#*****************************************************************************************************
# Subroutine Name         : validEmailAddress
# Objective               : validates the email address provided by the user in the configuration file
# Added By                : Dhritikana
#*****************************************************************************************************
sub validEmailAddress
{
        my $addr = $_[0];
        $addr = lc($addr);
        return(0) unless ($addr =~ /^[^@]+@([-\w]+\.)+[a-z]{2,}$/);
        #return(0) unless ($addr =~ /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,}?)$/i);
}

#******************************************************************************
# Subroutine Name         : terminateStatusRetrievalScript
# Objective               : terminates the Status Retrieval script in case it is running
# Added By                : 
#******************************************************************************
sub terminateStatusRetrievalScript()
{
	my $statusScriptName = "Status_Retrieval_Script.pl";
	my $statusScriptCmd = "ps -elf | grep $statusScriptName | grep -v grep";
	
	my $statusScriptRunning = `$statusScriptCmd`;
	
	if($statusScriptRunning ne "") {
		my @processValues = split /[\s\t]+/, $statusScriptRunning;
		my $pid = $processValues[3];
		
		`kill -s SIGTERM $pid`;
	}
}

#****************************************************************************************************
# Subroutine Name         : copyTempErrorFile
# Objective               : This subroutine copies the contents of the temporary error file to the 
#							Error File.
# Added By                : 
# Modified By			  : Deepak Chaurasia
#*****************************************************************************************************/
sub copyTempErrorFile()
{
	# if error file is empty then return 
	if(!-s $idevsErrorFile){
		#print $tHandle "\n returning \n";
		return;
	}
	
	#open the error file for read and if open fails then return
	if (! open(TEMP_ERRORFILE, "< $idevsErrorFile")) {
		print $tHandle "Could not open file $idevsErrorFile, Reason:$! $lineFeed";
		return;
	}
	
	#read error file content 
	my @tempErrorFileContents = ();	
	@tempErrorFileContents = <TEMP_ERRORFILE>;
	close TEMP_ERRORFILE; 
	
	#$file = $usrProfileDir."/$_[0]";
	my $file = $_[0];
	
	#open the App error file and if failed to open then return
	if (! open(ERRORFILE, ">> $file")) {     
		print $tHandle "Could not open file 'file' in copyTempErrorFile: $file, Reason:$! $lineFeed";
		return;
	}

	#write the content of error file in App error file
	$errorStr = join('\n', @tempErrorFileContents);
	print ERRORFILE $errorStr;
	close ERRORFILE;
	chmod 0777, $file;
}

#*******************************************************************************************
# Subroutine Name         : cleanProgressFile
# Objective               : erases the contents of the progress file
# Added By                : 
#*******************************************************************************************
sub cleanProgressFile()
{
	my $progressDetailsFilePath = ${$_[0]};
	if (open(PROGRESSFILE, "> $progressDetailsFilePath"))
	{
		close PROGRESSFILE;
		chmod 0777, $progressDetailsFilePath;
	}
	else
	{
		print $tHandle CONST->{'FileOpnErr'}.$progressDetailsFilePath." Reason:$! $lineFeed";
	}
}

#****************************************************************************************************
# Subroutine Name         : appendErrorFileContents
# Objective               : This subroutine appends the contents of the error file to the output file
#							and deletes the error file.
# Modified By                : Deepak Chaurasia
#*****************************************************************************************************/
sub appendErrorFileContents
{
	#print $tHandle "\n in appenderrorfilecontents $_[0] ";
	my $error_dir = $_[0]."/";
	#my @files_list = <$error_dir*>;
	my @files_list = `ls $error_dir`;
	#print $tHandle "\n error_dir = $error_dir and files_list = @files_list \n";
	my $fileopen = 0;
	chomp(@files_list);
	foreach my $file (@files_list) {
		chomp($file);
		if ( $file eq "." or $file eq "..") {
			next;
		}
		$file = $error_dir.$file;
		
		if(-s $file > 0){
			if($fileopen == 0){
				$summaryError.="$lineFeed"."_______________________________________________________________________________________";
				$summaryError.="$lineFeed"."|Error Report|"."$lineFeed";
				$summaryError.="_______________________________________________________________________________________$lineFeed";
			}
			$fileopen = 1;
			open ERROR_FILE, "<", $file or print $tHandle CONST->{'FileOpnErr'}." $file. Reason $!\n"; 
			while(my $line = <ERROR_FILE>) { 
				$summaryError.=$line;
			}
			close ERROR_FILE;
		}
	}	
}

#*************************************************************************************************
# Subroutine Name         : createLogFiles
# Objective               : Creates the Log Directory if not present, Creates the Error Log and  
#							Output Log files based on the timestamp when the backup/restore
#							operation was started, Clears the content of the Progress Details file 
#                           
# Added By                : 
#**************************************************************************************************
sub createLogFiles() 
{
	my $jobType = $_[0];
	our $progressDetailsFileName = "PROGRESS_DETAILS_".$jobType;
	our $outputFileName = $jobType;
	our $errorFileName = $jobType."_ERRORFILE";
	my $logDir = "$jobRunningDir/LOGS";
	$errorDir = "$jobRunningDir/ERROR";
	
	if($ifRetainLogs eq "NO") {
		chmod 0777, $logDir;
		rmtree($logDir);
	}

	if(!-d $logDir)
	{
		mkdir $logDir;
		chmod 0777, $logDir;
	}

	my $currentTime = localtime;
	$outputFilePath = $logDir.$pathSeparator.$outputFileName.$whiteSpace.$currentTime; 
	$errorFilePath = $errorDir.$pathSeparator.$errorFileName;
	#$progressDetailsFilePath = $logDir.$pathSeparator.$progressDetailsFileName;
	$progressDetailsFilePath = $usrProfileDir.$pathSeparator.$progressDetailsFileName;
}

#*******************************************************************************************
# Subroutine Name         :	convertFileSize
# Objective               :	converts the file size of a file which has been backed up/synced
#                           into human readable format
# Added By                : 
#******************************************************************************************
sub convertFileSize()
{
	my $fileSize = $_[0];
	my $fileSpec = "bytes";
	
	if($fileSize > 1023)
	{
		$fileSize /= 1024;
		$fileSpec = "KB";
	}
	
	if($fileSize > 1023)
	{
		$fileSize /= 1024;
		$fileSpec = "MB";
	}
	
	if($fileSize > 1023)
	{
		$fileSize /= 1024;
		$fileSpec = "GB";
	}
	
	if($fileSize > 1023)
	{
		$fileSize /= 1024;
		$fileSpec = "TB";
	}
	
	$fileSize = sprintf "%.2f", $fileSize;
	if(0 == ($fileSize - int($fileSize)))
	{
		$fileSize = sprintf("%.0f", $fileSize);
	}
	return $fileSize.$whiteSpace.$fileSpec;
}


#****************************************************************************************************
# Subroutine Name         : displayProgressBar.
# Objective               : This subroutine contains the logic to display the filename and the progress
#							bar in the terminal window.
# Added By                : 
#*****************************************************************************************************/
sub displayProgressBar()
{
	my $fileName = $_[0];
	my $percentComplete = $_[1];
	my $fileSize = $_[2];
	my $TotalSize = $_[3];
	my $kbps = $_[4];
	
	chop($percentComplete);
	
	if(!$lineFeedPrinted)
	{
		autoflush STDOUT;
		
		print "[$fileName]";
		print $whiteSpace;
		print "[$fileSize]";
		print $whiteSpace;
		print "[$TotalSize]";
		print $whiteSpace;
		print "[$kbps]";
		print $whiteSpace;
		print $percentComplete;
	}

	if($percentComplete eq "100")
	{
		if(!$lineFeedPrinted)
		{
			autoflush STDOUT;
			
			print $percent;
			
			$lineFeedPrint = true;
		}
	}
	
	if(!$lineFeedPrinted)
	{
		autoflush STDOUT;
		
		print "[";
		
		for(my $index = 0; $index < $percentComplete; $index+=4)
		{
			print $assignmentOperator;
		}
	
		print "]";
	}


	if($percentComplete eq "100")
	{
		if($lineFeedPrint and !$lineFeedPrinted)
		{
			autoflush STDOUT;
			
			print $lineFeed;
			
			$lineFeedPrinted = true;
		} 
	}
	else
	{
		autoflush STDOUT;
		
		print $carriageReturn;
		
		$lineFeedPrint = false;
		$lineFeedPrinted = false;
	}
}

#****************************************************************************************************
# Subroutine Name         : writeLogHeader.
# Objective               : This function will write user log header.
# Added By				  : Dhritikana
#*****************************************************************************************************/
sub writeLogHeader {
	my $flagToCheckSchdule = $_[0];
	# require to open log file to show job in progress as well as to log exclude details
	if(!open(OUTFILE, ">", $outputFilePath)){
		print CONST->{'CreateFail'}." $outputFilePath, Reason:$!";
		print $tHandle CONST->{'CreateFail'}." $outputFilePath, Reason:$!" and die;
	}
	chmod 0777, $outputFilePath;
	
	autoflush OUTFILE;
	my $host = `hostname`;
	chomp($host);
	
	autoflush OUTFILE;
	
	my $mailHeadA = $lineFeed."$jobType Start Time: $whiteSpace".(localtime)."$lineFeed";
	my $mailHeadB = undef;
	
	if($jobType eq "Backup") {
		$mailHeadB = "$jobType Type: $backupPathType $jobType $lineFeed";
	}
	$mailHeadB .= "Machine Name: $host $lineFeed".
			"Throttle Value: $bwThrottle $lineFeed".
			"$jobType Location: $location $lineFeed";
	
	my $LogHead = $mailHeadA."Username: $userName $lineFeed".$mailHeadB;				
	print OUTFILE $LogHead.$lineFeed;	
		
	my $mailHead = $mailHeadA.$mailHeadB;
	return $mailHead;	
}

#*******************************************************************************************
# Subroutine Name         :	writeOperationSummary
# Objective               :	This subroutine writes the restore summary to the output file.
# Added By                : 
#******************************************************************************************
sub writeOperationSummary()
{
	$filesConsideredCount = $totalFiles;
	chomp($filesConsideredCount);
	
	chmod 0777, $outputFilePath;
	# open output.txt file to write restore summary.
	if (!open(OUTFILE, ">> $outputFilePath")){ 
		print $tHandle CONST->{'FileOpnErr'}.$outputFilePath.", Reason:$! $lineFeed";
		return;
	}
	chmod 0777, $outputFilePath;
	
	if($failedFilesCount > 0 or $nonExistsCount >0) {
		appendErrorFileContents($errorDir);
		$summary .= $summaryError.$lineFeed;
		$failedFilesCount += $nonExistsCount;
	}	
	
	# construct summary message.
	my $mail_summary = undef;
	$summary .= $lineFeed."Summary: ".$lineFeed;
	if($_[0] == $backupOp) {
		$mail_summary .= CONST->{'TotalBckCnsdrdFile'}.$filesConsideredCount.
				$lineFeed.CONST->{'TotalBckFile'}.$successFiles.
				$lineFeed.CONST->{'TotalSynFile'}.$syncedFiles.
				$lineFeed.CONST->{'TotalBckFailFile'}.$failedFilesCount.
				$lineFeed.CONST->{'BckEndTm'}.$whiteSpace.localtime, $lineFeed;	
			
	}else 	{
			$mail_summary .= CONST->{'TotalRstCnsdFile'}.$filesConsideredCount.
					$lineFeed.CONST->{'TotalRstFile'}.$successFiles.
					$lineFeed.CONST->{'TotalSynFile'}.$syncedFiles.
					$lineFeed.CONST->{'TotalRstFailFile'}.$failedFilesCount.
					$lineFeed.CONST->{'RstEndTm'}.$whiteSpace.localtime, $lineFeed;
	}
	
	if($errStr ne "" &&  $errStr ne "SUCCESS"){
		$mail_summary .= $lineFeed.$lineFeed.$errStr.$lineFeed;
	}
	
	$summary .= $mail_summary;	
	$mail_content .= $mail_summary;
	print OUTFILE $summary;			
	close OUTFILE;	
}

#*******************************************************************************************
# Subroutine Name         :	createUserDir
# Objective               :	This subroutine creates directory for given path.
# Added By                : Dhritikana
#******************************************************************************************
sub createUserDir {
	$usrProfileDir = "$usrProfilePath/$userName";
	my $usrBackupDir = "$usrProfilePath/$userName/Backup";
	my $usrRestoreDir = "$usrProfilePath/$userName/Restore";
	$traceDir = "$usrProfileDir/.trace";
	$traceFileName = "$traceDir/traceLog.txt";
	
	my @dirArr = ($usrProfilePath, $usrProfileDir, $traceDir, $usrBackupDir, $usrRestoreDir);
	
	foreach my $dir (@dirArr) {
		if(! -d $dir) {
			$mkDirFlag = 1;
			my $ret = mkdir($dir);
			if($ret ne 1) {
				print CONST->{'MkDirErr'}.$dir.": $!".$lineFeed;
				exit 1;
			}
		}
		chmod 0777, $dir;
	}	
	
	unless(open($tHandle, ">> $traceFileName")) {
		print $lineFeed."Couldn't create trace file, Reason: $!".$lineFeed and die;
	}
	chmod 0777, $traceFileName;
}

#*******************************************************************************************
# Subroutine Name         :	pidAliveCheck
# Objective               :	This subroutine checks if another job is running via pidpath
#							path availability and creates pidpath if not available and locks it
# Added By                : Dhritikana
#************************************************************************************************/
sub pidAliveCheck {
	my $pidMsg = undef;
    
    if(-e $pidPath) {
		$pidMsg = "Another $jobType job is running. $!\n";
		print $pidMsg;
		print $tHandle $pidMsg;
		return 0;
	}
	
	if(!open(PIDFILE, '>>', $pidPath)) {
		print $tHandle "Cannot open '$pidPath' for writing: $!";
		return 0;
	}
	chmod 0777, $pidPath;
		
	#if(!flock(PIDFILE, &F_SETLK)) {
	#	$pidMsg = "Another $jobType job is running. $!\n";
	#	print $pidMsg;
	#	print $tHandle $pidMsg;
	#	return 0;
	#}
	
	return 1;
}

#*******************************************************************************************
# Subroutine Name         :	backupTypeCheck
# Objective               : This subroutine checks if backup type is either Mirror or Relative
# Added By                : Dhritikana
#************************************************************************************************/
sub backupTypeCheck {
	$backupPathType = lc($backupPathType);
	if($backupPathType eq "relative") {
		$relative = 0;
	} elsif($backupPathType eq "mirror") {
		$relative = 1;
	}
	else{
		print CONST->{'WrongBackupType'}.$lineFeed;
		print $tHandle CONST->{'WrongBackupType'}.$lineFeed;
		return 0;
	}
	return 1;
}

1;
