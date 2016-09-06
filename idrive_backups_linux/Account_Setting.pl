#!/usr/bin/perl

#use strict;
#use warnings;

use FileHandle;
use File::Path;
use File::Copy;
use Constants 'CONST';

if( !-e "CONFIGURATION_FILE")  {
	unless(open FILE, "> CONFIGURATION_FILE") {
		die " Unable to open CONFIGURATION_FILE. Reason: $!";
	}
	close FILE;
	chmod 0777, "CONFIGURATION_FILE";
}

require 'header.pl';

my $encType = undef;
my $idevsZip = undef;
my $prevPathIdev = undef;
my $idevsHelpLen = undef;
my $wrtToErr = "2>tracelog.txt";
my $idevsUtilLink = undef;
my $emailAddr = undef;
my $NotLoggedIn = 0;

my( $proxyOn, $proxyIp, $proxyPort, $proxyUsername, $proxyPassword, $proxyString) = undef;
my $pvt = undef;
my $defaultFolderExists = undef;

# $appTypeSupport should be ibackup for ibackup and idrive for idrive#
# $appType should be IBackup for ibackup and IDrive for idrive        #
my ($appTypeSupport,$appType) = getAppType();

##############################################
#Subroutine that processes SIGINT and SIGTERM#
#signal received by the script during backup #
##############################################
$SIG{INT} = \&cancelProcess;
$SIG{TERM} = \&cancelProcess;
$SIG{TSTP} = \&cancelProcess;
$SIG{QUIT} = \&cancelProcess;
	
system("clear");

print $whiteSpace.CONST->{'CheckPreq'}.$lineFeed;
my $unzip = checkPrerequisite(\"unzip");
my $curl = checkPrerequisite(\"curl");
my $wget = checkPrerequisite(\"wget");

print $lineFeed.$whiteSpace.CONST->{'Instruct'}.$lineFeed.$whiteSpace;

# get user name input
print $lineFeed.$whiteSpace.CONST->{'AskUname'}.$lineFeed.$whiteSpace;
$userName = getInput();
checkInput(\$userName);

if(!-e $pwdPath) {
	$NotLoggedIn = 1;
}

#Get Previous username
my $loggedInUser = getCurrentUser();

if($loggedInUser eq $userName and $NotLoggedIn ne 1) {
	print CONST->{'LoginAlready'}.$lineFeed;
	exit;
}

if($loggedInUser ne $userName) {
	my $TmpPwdPath = "$usrProfilePath/$loggedInUser/.IDPWD";
	if( -e $TmpPwdPath and -f $TmpPwdPath) {
		print "User \"$loggedInUser\" is already logged in. Please logout and try again.".$lineFeed;
		exit 1;
	}
}

# creating user profile path and job path
print $lineFeed.$whiteSpace.CONST->{'CrtUserDir'}.$lineFeed.$whiteSpace if(! -d $usrProfileDir);
createUserDir();
print $lineFeed.$whiteSpace.CONST->{'DirCrtMsg'}.$lineFeed.$whiteSpace if($mkDirFlag);


# Trace Log Entry #
my $curFile = basename(__FILE__);
message("$lineFeed File: $curFile $lineFeed ---------------------------------------- $lineFeed");

# get password input
print $lineFeed.$whiteSpace.CONST->{'AskPword'}.$lineFeed.$whiteSpace;
system('stty','-echo');
my $pwd = getInput();
checkInput(\$pwd);
system('stty','echo');

# loading username in global variables
$serverfile = "$usrProfilePath/$userName/.serverAddress.txt";
$pwdPath = "$usrProfilePath/$userName/.IDPWD";
$pvtPath = "$usrProfilePath/$userName/.IDPVT";
$enPwdPath = "$usrProfilePath/$userName/.IDENPWD";

# get proxy details
getProxyDetails();

# checking compatible idevsutil 
my $EvsOn = checkIfEvsWorking();
if($EvsOn eq 0) {
	my $retType = getCompatibleEvsBin(\$wgetCommand);
}

# create encode file for password
createEncodeFile($pwd, $pwdPath) and $pathFlag = 1;

# get server address
unless(-e $serverfile || -s $serverfile) {
	getServerAddr("modProxy", $proxyString);
}
       
if( -e $serverfile) {
	open FILE, "<", $serverfile or (print $tHandle $lineFeed.CONST->{'FileOpnErr'}.$serverfile." , Reason:$! $lineFeed" and die);
	$serverAddress = <FILE>;
	chomp($serverAddress);
	close FILE;
} else {
	cancelProcess();
}
	
my ($desc, $plan_type, $message, $cnfgstat, $enctype, $res) = undef;
getAccountInfo();

accountErrInfo();

setConfDetails();

updateConfFile();

#Set all permission to the files
chmod 0777, <$currentDir/*>;

#****************************************************************************
# Subroutine Name         : checkPrerequisite
# Objective               : Check if required binary executables are installed in 
#							user system or not.
# Added By                : Dhritikana
#****************************************************************************/
sub checkPrerequisite {
	my $pckg = ${$_[0]};
	my $pckgPath = `which $pckg 2>/dev/null`;
	chomp($pckgPath);

	if($pckgPath) {
		print $whiteSpace.$pckg.$whiteSpace.CONST->{'IsAbvl'}.$lineFeed;
		return $pckgPath;
	} else {
		print $whiteSpace.$pckg.$whiteSpace.CONST->{'NotAbvl'};
		print $whiteSpace.CONST->{'SuggestInstall'}.$lineFeed;
		cancelProcess();
	}
}

#****************************************************************************
# Subroutine Name         : cancelProcess
# Objective               : Cleanup if user cancel.
# Added By                : Dhritikana
#****************************************************************************/
sub cancelProcess {
	if($pathFlag) {
		unlink($pwdPath);
		unlink($pvtPath);
	}

	if($mkDirFlag) {
		my $tempTrace = $currentDir."/traceLog.txt";
		move($traceFileName, $tempTrace);
		rmtree($usrProfileDir);
	}
	
	system('stty','echo');
	#system("killall $idevsutilBinaryName 1>/dev/null 2>/dev/null"); ###NEED CHECKING
	unlink($idevsOutputFile);
	unlink($idevsErrorFile);
	exit 1;
}

#****************************************************************************
# Subroutine Name         : getInput
# Objective               : Get user input from terminal. 
# Added By                : Dhritikana
#****************************************************************************/
sub getInput {
	#autoflush STDIN;
	
	my $input = <>;
	chomp($input);
	$input =~ s/^\s+|\s+$//;
	return $input;
}

#****************************************************************************
# Subroutine Name         : getInput
# Objective               : Get user input from terminal. 
# Added By                : Dhritikana
#****************************************************************************/
sub getLocationInput {
	my $flag = $_[0];
	
	while(1) {
		my $input = <>;
		chomp($input);
		
		if($input eq "") {
			if($flag eq "backupHost" or $flag eq "restoreHost" ) {
				return $input;
			} elsif ($flag eq "rloc") {
				$input = "$usrProfilePath/$userName/Restore_Data";
				return $input;
			}
		}

		$input =~ s/^\s+\/+|^\/+/\//g; ## Replacing starting "/"s with one "/"
		$input =~ s/^\s+//g; ## Removing Blank spaces
		
		if($flag eq "backupHost") {
			$input =~ s/^\/+$|^\s+\/+$//g; ## Removing if only "/"(s) to avoid root 
		}
		
		if(length($input) <= 0) {
			print $whiteSpace.CONST->{'InvLocInput'};
			print $whiteSpace.CONST->{'EnterAgn'}.$lineFeed.$whiteSpace;
		} else {
			return $input;
		}
	}
}

#****************************************************************************
# Subroutine Name         : checkInput
# Objective               : Get user input from terminal. 
# Added By                : Dhritikana
#****************************************************************************/
sub checkInput {
	while(${$_[0]} eq "") {
		print $whiteSpace.CONST->{'InputEmptyErr'}.$lineFeed.$whiteSpace;
		${$_[0]} = getInput();
	}
}

#**********************************************************************************************
# Subroutine Name         : getProxyDetails
# Objective               : Get proxy informations from user and form wget Command based on it. 
# Added By                : Dhritikana
#**********************************************************************************************/
sub getProxyDetails {
	print $lineFeed.$whiteSpace.CONST->{'AskIfProxy'}.$lineFeed;
	$confirmationChoice = undef;
	getConfirmationChoice();
	
	if($confirmationChoice eq "n" || $confirmationChoice eq "N") {
		$proxyOn = 0;
	} elsif( $confirmationChoice eq "y" || $confirmationChoice eq "Y") {
		print $lineFeed.$whiteSpace.CONST->{'AskProxyIp'}.$lineFeed.$whiteSpace;
		$proxyIp = getInput();
		checkInput(\$proxyIp);
		print $lineFeed.$whiteSpace.CONST->{'AskProxyPort'}.$lineFeed.$whiteSpace;
		$proxyPort = getInput();
		checkInput(\$proxyPort);
		print $lineFeed.$whiteSpace.CONST->{'AskProxyUname'}.$lineFeed.$whiteSpace;
		$proxyUsername = getInput();
		print $lineFeed.$whiteSpace.CONST->{'AskProxyPass'}.$lineFeed.$whiteSpace;
		$proxyPassword = getInput();
		$proxyOn = 1;
		$proxyString = "$proxyUsername:$proxyPassword\@$proxyIp:$proxyPort";
		
		foreach ($proxyUsername, $proxyPassword) {
				$_ =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
		}
	}
}

#***************************************************************************************
# Subroutine Name         : checkIfEvsWorking
# Objective               : Checks if existing EVS binary is working or not.
# Added By                : Dhritikana
#*****************************************************************************************/
sub checkIfEvsWorking {
	if(!-f $idevsutilBinaryName) {
		return 0;
	}
	
	chmod 0777, $idevsutilBinaryName;
	my @idevsHelp = `$idevsutilBinaryPath -h 2>/dev/null`;
	$idevsHelpLen = @idevsHelp;
	if($idevsHelpLen < 50 ) {
		return 0;
	}
}

#***************************************************************************************
# Subroutine Name         : getCompatibleEvsBin
# Objective               : Downloads the idevsutil binary zip freshly. Extracts it and 
#							keep in the working folder.
# Added By                : Dhritikana
# Modified By			  : Deepak
#*****************************************************************************************/
sub getCompatibleEvsBin {
	print $lineFeed.$whiteSpace.CONST->{'EvsCmplCheck'}.$lineFeed.$whiteSpace;
	
	my $count = 0;
	while(1) {
		# Getting EVS link based on machine
		getCompatibleEvsLink();
		
		# removing old zip and downloading new zip based on EVS link received
		my $wgetCmd = formWgetCmd(\$proxyOn);		
		
		if(-e $idevsZip) {
			unlink $idevsZip;
		}
		
		`$wgetCmd`;

		# failure handling for wget command
		open FILE, "<", "tracelog.txt" or die "Couldn't open file: $!"; 
		my $wgetRes = join("", <FILE>); 
		close FILE;

		#message(" wget res :$wgetRes: ");
		
		if($wgetRes =~ /failed:|failed: Connection refused|failed: Connection timed out|Giving up/ || $wgetRes eq "") {
			print $lineFeed.$whiteSpace.CONST->{'ProxyErr'}.$lineFeed.$whiteSpace;
			print $tHandle "$lineFeed WGET for EVS Bin: $wgetRes $lineFeed";
			cancelProcess();
		}
		
		if($wgetRes =~ /Unauthorized/) {
			print $lineFeed.$whiteSpace.CONST->{'ProxyUserErr'}.$lineFeed.$whiteSpace;
			print $tHandle "$lineFeed WGET for EVS Bin: $wgetRes $lineFeed";
			cancelProcess();
		}
		
		unlink "tracelog.txt";

		#cleanup the unzipped folder before unzipping new zipped file
		if(-e $prevPathIdev) {
			#system("rm -rf \"$prevPathIdev\"");
			rmtree($prevPathIdev);
		}

		if(!-e $idevsZip) {
			next;
		}
		#unzip the zipped file and in case of error exit
		my $idevsZipCmd = $idevsZip;                                                
		$idevsZipCmd =~ s/\'/\'\\''/g;    
		$idevsZipCmd = "'".$idevsZipCmd."'";                      

		system("$unzip $idevsZipCmd $wrtToErr");
		if(-s "tracelog.txt" ) {
			print $whiteSpace.CONST->{'TryAgain'}.$lineFeed;
			cancelProcess();
		}

		#remove the old evs binary and copy the new one with idevsutil name
		unlink($idevsutilBinaryPath);
		my $PreEvsPath = $prevPathIdev."idevsutil";
		rename $PreEvsPath, $idevsutilBinaryPath;

		# check if new evs binary exist or exit
		if(! -e $idevsutilBinaryPath) {
			print $lineFeed.$whiteSpace.CONST->{'TryAgain'}.$lineFeed;
			cancelProcess();
		}

		# provide permission to EVS binary and execute help command to find if binary is compatible one
		chmod 0777, $idevsutilBinaryPath;
		my @idevsHelp = `$idevsutilBinaryPath -h 2>/dev/null`;
		$idevsHelpLen = @idevsHelp;
		
		if(50 <= $idevsHelpLen) {
			print $lineFeed.$whiteSpace.CONST->{'EvsInstSuccess'}.$lineFeed.$whiteSpace;
			#Cleaning evs zip file and evs folder
			#system("rm -rf \"$prevPathIdev\"");
			rmtree($prevPathIdev);
			unlink $idevsZip;
			return;
		}
		else{
			if(-e $idevsZip) {
				unlink $idevsZip;
			}
			
			#cleanup the unzipped folder before unzipping new zipped file
			if(-e $prevPathIdev) {
				#system("rm -rf \"$prevPathIdev\"");
				rmtree($prevPathIdev);
			}		
		}
	}
}

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

#***************************************************************************************
# Subroutine Name         : getMenuChoice
# Objective               : get Menu choioce to check if user wants to configure his/her 
#							with Default or Private Key.
# Added By                : Dhritikana
#****************************************************************************************/
sub getMenuChoice {
  while(!defined $menuChoice) {
    print $whiteSpace.CONST->{'EnterChoice'}.$whiteSpace;
    $menuChoice = <>;
    chomp $menuChoice;

    $menuChoice =~ s/^\s+|\s+$//;

    if($menuChoice =~ m/^\d$/) {
      if($menuChoice < 1 || $menuChoice > 2) {
        $menuChoice = undef;
        print $whiteSpace.CONST->{'InvalidChoice'}.$whiteSpace;
      } 
    }
    else {
      $menuChoice = undef;
      print $whiteSpace.CONST->{'InvalidChoice'}.$whiteSpace;
    }
  }
}

#***********************************************************************************
# Subroutine Name         : checkPvtKeyCondtions
# Objective               : check if given Private Key satisfy the conditions.
# Added By                : Dhritikana
#************************************************************************************/
sub checkPvtKeyCondtions {
	if(length(${$_[0]}) >= 6 && length(${$_[0]}) <= 250) {
		return 1;
	} else {
		print $lineFeed.$whiteSpace.CONST->{'AskPvtWithCond'}.$lineFeed.$whiteSpace;
		return 0;
	}
}

#***********************************************************************************
# Subroutine Name         : confirmPvtKey
# Objective               : check user given Private key equality and confirm.
# Added By                : Dhritikana
#************************************************************************************/
sub confirmPvtKey {
	my $count = 0;
	while($count < 4) {
		print $lineFeed.$whiteSpace.CONST->{'AskPvtAgain'}.$lineFeed.$whiteSpace;
		my $pvtKeyAgin = getInput();
		if($pvt ne $pvtKeyAgin) {
			print $lineFeed.$whiteSpace.CONST->{'PvtErr'}.$lineFeed.$whiteSpace;
			$count++;
		} else {
			print $lineFeed.$whiteSpace.CONST->{'ConfirmPvt'}.$lineFeed.$whiteSpace;
			last;
		}
		if($count eq 3) {
			print $lineFeed.$whiteSpace.CONST->{'TryAgain'}.$lineFeed.$whiteSpace;
			cancelProcess();
		}
	}
}

#********************************************************************************************
# Subroutine Name         : checkIfExists
# Objective               : check if any particular file is not present in the system.
# Added By                : Dhritikana
#********************************************************************************************/
sub checkIfExists {
	if( ! -e ${$_[0]}) {
		print $lineFeed.$whiteSpace.${$_[0]}.$whiteSpace.CONST->{'AskPvtAgain'}.$lineFeed.$whiteSpace;
		exit(1);
	}
}

sub configAccount {
	print $lineFeed.$whiteSpace.CONST->{'AskConfig'}.$lineFeed;
	$confirmationChoice = undef;
	getConfirmationChoice();
	if($confirmationChoice eq "N" || $confirmationChoice eq "n") {
		exit 0;
	}
	print $whiteSpace.CONST->{'AskDefAcc'}.$lineFeed;
	print $whiteSpace.CONST->{'AskPvtAcc'}.$lineFeed;
	getMenuChoice();
	if($menuChoice eq "2") {
		$encType = "PRIVATE";
		my $retVal = undef;
		while(!$retVal) {
			print $lineFeed.$whiteSpace.CONST->{'AskPvt'}.$lineFeed.$whiteSpace;
			$pvt = getInput();
			$retVal = checkPvtKeyCondtions(\$pvt);
		}
		confirmPvtKey();
	} elsif( $menuChoice eq "1") {
		$encType = "DEFAULT";
	}
	
	createEncodeFile($pvt, $pvtPath);
	
	print $tHandle "$lineFeed configureAccount : ";
	
	my $configUtf8File = getOperationFile($configOp, $encType, "modProxy", $proxyString);
	chomp($configUtf8File);
	$configUtf8File =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$configUtf8File."'".$whiteSpace.$errorRedirection;
	my $commandOutput = `$idevsutilCommandLine`;
	print $tHandle "$lineFeed $commandOutput $lineFeed";
	unlink $configUtf8File;
}

#****************************************************************************************************
# Subroutine Name         : getArmEvsLink
# Objective               : This subroutine finds the system compatible EVS binary downloadable link
#							for arm machines
# Added By                : Deepak.
#****************************************************************************************************/
sub getArmEvsLink
{
	#try with qnap arm evs binary
	if($idevsUtilLink eq ""){
		$idevsUtilLink = $EvsQnapArmBin;
		$idevsZip = $currentDir."/QNAP_ARM.zip";
		$prevPathIdev = "QNAP ARM/";
	}
	elsif($idevsUtilLink eq $EvsQnapArmBin)
	{
		#try with synology arm evs binary
		$idevsUtilLink = $EvsSynoArmBin;
		$idevsZip = $currentDir."/synology_ARM.zip";
		$prevPathIdev = "synology_ARM/";
	}
	elsif($idevsUtilLink eq $EvsSynoArmBin)
	{
		#try with netgear arm evs binary
		$idevsUtilLink = $EvsNetgArmBin;
		$idevsZip = $currentDir."/Netgear_ARM.zip";
		$prevPathIdev = "Netgear_ARM/";
	}
	elsif($idevsUtilLink eq $EvsNetgArmBin)
	{
		#try with universal evs binary
		$idevsUtilLink = $EvsUnvBin;
		$idevsZip = $currentDir."/idevsutil_linux_universal.zip";
		$prevPathIdev = "idevsutil_linux_universal/";
	}
	else
	{
		print $lineFeed.$whiteSpace.CONST->{'EvsMatchError'}.$lineFeed.$whiteSpace;
		print $tHandle $lineFeed.$whiteSpace.CONST->{'EvsMatchError'}.$lineFeed.$whiteSpace;
		cancelProcess();
	}
}

#****************************************************************************************************
# Subroutine Name         : get32bitEvsLink
# Objective               : This subroutine finds the system compatible EVS binary downloadable link
#							for 32 bit and 64 bit machines
# Added By                : Deepak.
#****************************************************************************************************/
sub get32bitEvsLink {
	if($idevsUtilLink eq ""){
		#try with linux 32 evs binary
		$idevsUtilLink = $EvsBin32;
		$idevsZip = $currentDir."/idevsutil_linux.zip";
		$prevPathIdev = "idevsutil_linux/";
	}
	elsif($idevsUtilLink eq $EvsBin32){
		#try with qnap 32 evs binary
		$idevsUtilLink = $EvsQnapBin32_64;
		$idevsZip = $currentDir."/QNAP_Intel_Atom_64_bit.zip";
		$prevPathIdev = "QNAP Intel Atom 64 bit/";
	}
	elsif($idevsUtilLink eq $EvsQnapBin32_64){
		#try with synology 32 evs binary
		$idevsUtilLink = $EvsSynoBin32_64;
		$idevsZip = $currentDir."/synology_64bit.zip";
		$prevPathIdev = "synology_64bit/";
	}
	elsif($idevsUtilLink eq $EvsSynoBin32_64){
		#try with netgear 32 evs binary
		$idevsUtilLink = $EvsNetgBin32_64;
		$idevsZip = $currentDir."/Netgear_64bit.zip";
		$prevPathIdev = "Netgear_64bit/";
	}
	elsif($idevsUtilLink eq $EvsNetgBin32_64){
		#try with linux universal evs binary
		$idevsUtilLink = $EvsUnvBin;
		$idevsZip = $currentDir."/idevsutil_linux_universal.zip";
		$prevPathIdev = "idevsutil_linux_universal/";
	}
	else{
		print $lineFeed.$whiteSpace.CONST->{'EvsMatchError'}.$lineFeed.$whiteSpace;
		print $tHandle $lineFeed.$whiteSpace.CONST->{'EvsMatchError'}.$lineFeed.$whiteSpace;
		cancelProcess();
	}
}

#****************************************************************************************************
# Subroutine Name         : get64bitEvsLink
# Objective               : This subroutine finds the system compatible EVS binary downloadable link
#							for 64 bit and 64 bit machines
# Added By                : Deepak.
#****************************************************************************************************/
sub get64bitEvsLink 
{
	if($idevsUtilLink eq ""){
		$idevsUtilLink = $EvsBin64;
		$idevsZip = $currentDir."/idevsutil_linux64.zip";
		$prevPathIdev = "idevsutil_linux64/";
		return;
	}
	elsif($idevsUtilLink eq $EvsBin64){
		$idevsUtilLink = undef;
	}
	get32bitEvsLink();
}

#****************************************************************************************************
# Subroutine Name         : getCompatibleEvsLink
# Objective               : This subroutine finds the system compatible EVS binary downloadable link.
# Added By                : Dhritikana.
#****************************************************************************************************/
sub getCompatibleEvsLink {
	my $uname = `uname -m`;
	
	if($uname =~ /i686|i386/) {		# checking for all available 32 bit binaries
		get32bitEvsLink();
	} 
	elsif($uname =~ /x86_64|ia64/) {	# checking for all available 64 bit binaries
		get64bitEvsLink();
	} 
	elsif($uname =~ /arm/){			# checking for all available arm binaries
		getArmEvsLink();
	}
	else {
		print $lineFeed.$whiteSpace.CONST->{'EvsMatchError'}.$lineFeed.$whiteSpace;
		print $tHandle $lineFeed.$whiteSpace.CONST->{'EvsMatchError'}.$lineFeed.$whiteSpace;
		cancelProcess();
	}
}

#**************************************************************************************************
# Subroutine Name         : formWgetCmd
# Objective               : Form wget command to download EVS binary based on proxy settings.
# Added By                : Dhritikana.
#**************************************************************************************************/
sub formWgetCmd {
	my $wgetXmd = undef;
	if(${$_[0]} eq 1) {
		my $proxy = undef;
		if($proxyUsername eq "") {
			$proxy = 'http://'.$proxyIp.':'.$proxyPort;
		} else {
			$proxy = 'http://'.$proxyUsername.':'.$proxyPassword.'@'.$proxyIp.':'.$proxyPort;
		}
		#$wgetCmd = "$wget \"--no-check-certificate\" \"--tries=2\" -e \"http_proxy = $proxy\" --proxy-user \"$proxyUsername:$proxyPassword\" $idevsUtilLink \"--output-file=tracelog.txt\" ";
		$wgetCmd = "$wget \"--no-check-certificate\" \"--tries=2\" -e \"http_proxy = $proxy\" $idevsUtilLink \"--output-file=tracelog.txt\" ";
	} elsif(${$_[0]} eq 0) {
			$wgetCmd = "$wget \"--no-check-certificate\" \"--output-file=tracelog.txt\" $idevsUtilLink";
	}
	#message(" wget cmd :$wgetCmd: ");
	return $wgetCmd;
}

#****************************************************************************************************
# Subroutine Name         : getAccountInfo.
# Objective               : Gets the user account information by using CGI.
# Added By                : Dhritikana.
#*****************************************************************************************************/
sub getAccountInfo {
	print $lineFeed.$whiteSpace.CONST->{'verifyAccount'}.$lineFeed.$whiteSpace;
	my $PATH = undef;
	if($appType eq "IDrive") {
		$PATH = $IDriveAccVrfLink;
	} elsif($appType eq "IBackup") {
		$PATH = $IBackupAccVrfLink;
	}
	
	my $encodedUname = $userName;
	my $encodedPwod = $pwd;
	#URL DATA ENCODING#
	foreach ($encodedUname, $encodedPwod) {
			$_ =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	}
	
	my $data = 'username='.$encodedUname.'&password='.$encodedPwod;

	#$res = `$curl -x http://$proxyIp:$proxyPort --proxy-user "$proxyUsername:$proxyPassword" -L -s -d '$data' '$PATH'` or print "$linefeed Couldn't. Reason: $! $linefeed";
	if($proxyOn eq 1) {
		$curlCmd = "$curl --max-time 15 -x http://$proxyIp:$proxyPort --proxy-user $proxyUsername:$proxyPassword -L -s -k -d '$data' '$PATH' $wrtToErr";
	} else {
		$curlCmd = "$curl --max-time 15 -s -k -d '$data' '$PATH' $wrtToErr";
	}
	my $flag = 0;
	#message(" curl cmd :$curlCmd: ");
	
	$res = `$curlCmd` or print "$linefeed $curl failed." and $flag = 1;
	if($res =~ /FAILURE/) {
		if($res =~ /passwords do not match/) {
			print "$linefeed $curl failed, Reason: passwords do not match\n";
			cancelProcess();
		}
	} elsif ($res =~ /SSH-2.0-OpenSSH_6.8p1-hpn14v6|Protocol mismatch/) {
		print "$linefeed $curl failed, Reason: $res\n";
		cancelProcess();
	}
	message(" curl res :$res: ");
	
	if( -s "tracelog.txt" ) {
		print CONST->{'ProxyErr'}.$lineFeed;
		#unlink "tracelog.txt";
		cancelProcess();
	}
	elsif($flag){
		print CONST->{'ProxyErr'}.$lineFeed;
		#unlink "tracelog.txt";
		cancelProcess();
	}
	
	if(!$res && !$proxyIp) {
		print $lineFeed.$whiteSpace.CONST->{'NetworkErr'}.$lineFeed.$whiteSpace;
		cancelProcess();
	} elsif( $res =~ /Unauthorized/) {
		print $lineFeed.$whiteSpace.CONST->{'ProxyUserErr'}.$lineFeed.$whiteSpace;
		cancelProcess();
	}
	
	parseXMLOutput(\$res);
	$encType = $evsHashOutput{"enctype"};
	$plan_type = $evsHashOutput{"plan_type"};
	$message = $evsHashOutput{"message"};
	$cnfgstat = $evsHashOutput{"cnfgstat"};
	$desc = $evsHashOutput{"desc"};
	
	#parseXMLOutput(\$res, \$plan_type, \"plan_type");
	#parseXMLOutput(\$res, \$message, \"message");
	#parseXMLOutput(\$res, \$cnfgstat, \"cnfgstat");
	#parseXMLOutput(\$res, \$desc, \"desc");
	#parseXMLOutput(\$res, \$encType, \"enctype");
}

#***************************************************************************************************
# Subroutine Name         : setBackupLocation
# Objective               : Create a backup directory on user account in order to check if 
#							user provided private key is correct. Ask user for correct private key
#							incase it is wrong.
# Added By                : Dhritikana.
#***************************************************************************************************/
sub setBackupLocation {
	# create user backup directory on IDrive account
	my $createDirUtfFile = getOperationFile($createDirOp, $encType, "modProxy", $proxyString);
	chomp($createDirUtfFile);
	$createDirUtfFile =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$createDirUtfFile."'".$whiteSpace.$errorRedirection;
	$commandOutput = `$idevsutilCommandLine`;
	unlink($createDirUtfFile);
	
	if($commandOutput =~ /encryption verification failed|key must be between 4 and 256/){
		return 0;
	} 
	elsif($commandOutput =~ /created successfull/) {
		#print $lineFeed.$whiteSpace.CONST->{'MkBackupDir'}.$lineFeed.$whiteSpace;
		return 1;
	} elsif($commandOutput =~ /file or folder exists/) {
		return 2;
	}
	else {
		print "$commandOutput\n";
		exit 1;
	}
}

#***************************************************************************************
# Subroutine Name         : accountErrInfo
# Objective               : Provides the user account error information before 
#							proceeding Account setting.
# Added By                : Dhritikana
#****************************************************************************************/
sub accountErrInfo {
	if($message !~ /SUCCESS/) {
		print "";
		print "\n ".$evsHashOutput{'desc'}." \n";
		cancelProcess();
	}
	
	if($plan_type eq "Mobile-Only") {
		print "\n $evsHashOutput{'desc'}\n";
		cancelProcess();
	}
}

#**********************************************************************************************************
# Subroutine Name         : verifyPvtKey
# Objective               : This subroutine varifies the private key by trying to create backup directory. 
# Added By                : Dhritikana
#*********************************************************************************************************/
sub verifyPvtKey {
	$backupHost = `hostname`;
	chomp($backupHost);
	
	print $lineFeed.$whiteSpace.CONST->{'verifyPvt'}.$lineFeed.$whiteSpace;
	my $retType = setBackupLocation();
	
	my $count = 0;
	while($retType eq 0) {
		if($count eq 2) {
			print $lineFeed.$whiteSpace.CONST->{'TryAgain'}.$lineFeed;
			cancelProcess();
		}
		print $lineFeed.$whiteSpace.CONST->{'AskCorrectPvt'}.$lineFeed.$whiteSpace;
		system('stty','-echo');
		$pvt = getInput();
		system('stty','echo');
		
		checkInput(\$pvt);
		createEncodeFile($pvt, $pvtPath);
		
		$retType = setBackupLocation();
		$count++;
	}
	
	$defaultFolderExists = $retType;
	print $lineFeed.$whiteSpace.CONST->{'verifiedPvt'}.$lineFeed.$whiteSpace;
}

#****************************************************************************************************
#Subroutine Name        	: renameBackLoc
#Objective             		: This subroutine renames the default backup location created during  
#							  private Key verification.
#Added By                	: Dhritikana
#****************************************************************************************************/
sub renameBackLoc {
	my $oldPath = ${$_[0]};
	my $newPath = ${$_[1]};
	
	my $renameDirUtfFile = getOperationFile($renameOp, $encType, $oldPath, $newPath,  "modProxy", $proxyString);
	chomp($renameDirUtfFile);
	$tmpRenameDirUtfFile = $renameDirUtfFile;
	$tmpRenameDirUtfFile =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$tmpRenameDirUtfFile."'";

	$commandOutput = `$idevsutilCommandLine`;
	unlink($renameDirUtfFile);
	
	if($commandOutput =~ /renamed /){
		return 1;
	} else {
		if( -e $idevsErrorFile && -s $idevsErrorFile) {
			unless(open ERRORFILE, "$idevsErrorFile") {
				die "Unable to open $idevsErrorFile\n";
			}
			$errMsg = <ERRORFILE>;
			if($errMsg =~ /new path already exists/) {
				close ERRORFILE;
				unlink $idevsErrorFile;
				return 1;
			}
			`echo $errMsg > tracelog.txt`;
		}
		print CONST->{'BackLocCrFailMsg'};
		cancelProcess();
	}
}

#****************************************************************************************************
#Subroutine Name        	: checkRestoreFromLoc
#Objective             		: This subroutine verifies if RestoreFrom Location exists
#Added By                	: Dhritikana
#****************************************************************************************************/
sub getRestoreFromLoc {
	while(1) {
		print $lineFeed.$whiteSpace.CONST->{'AskRestoreFrom'}.$lineFeed.$whiteSpace;
		
		$restoreHost = getLocationInput("restoreHost");

		if($restoreHost eq ""){
			$restoreHost = `hostname`;
	        chomp($restoreHost);
		} elsif($restoreHost eq "/") {
			last;
		}
		
		if(substr($restoreHost, 0, 1) ne "/") {
			$restoreHost = "/".$restoreHost;
		}
		
		my $authUtfFile = getOperationFile($propertiesOp, "modProxy", $proxyString);
		chomp($authUtfFile);
		$authUtfFile =~ s/\'/\'\\''/g;
		
		$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$authUtfFile."'".$whiteSpace.$errorRedirection;
		my $commandOutput = `$idevsutilCommandLine`;
		print $tHandle "$lineFeed $commandOutput $lineFeed";
		unlink $authUtfFile;
		
		if($commandOutput =~ /No such file or directory/) {
			print $lineFeed.$whiteSpace.CONST->{'NoFileEvsMsg'};
			print $lineFeed.$whiteSpace.CONST->{'RstFromGuidMsg'}.$lineFeed;
		} else {
			last;
		}
	}
	print $whiteSpace.CONST->{'RestoreLocMsg'}.$whiteSpace."\"$restoreHost\"".$lineFeed;
}

#**********************************************************************************************************
# Subroutine Name         : setConfDetails
# Objective               : This subroutine configures the user account if not set and asks user details 
#							which are required for setting the account.
# Added By                : Dhritikana
#*********************************************************************************************************/
sub setConfDetails {
	# Based on Config Status configures the "NOT SET" account
	if($cnfgstat eq "NOT SET") {
		configAccount();
		$backupHost = `hostname`;	
	} elsif($cnfgstat eq "SET") {
		# For Private Account Verifies the Private Encryption Key
		if($encType eq "PRIVATE") {
			print $lineFeed.$whiteSpace.CONST->{'AskPvt'}.$lineFeed.$whiteSpace;
			system('stty','-echo');
			$pvt = getInput();
			system('stty','echo');
			checkInput(\$pvt);
			createEncodeFile($pvt, $pvtPath);
			verifyPvtKey();
		}
	}
		
	# get user backup location
	print $lineFeed.$whiteSpace.CONST->{'AskBackupLoc'}.$lineFeed.$whiteSpace;
	my $backupHostTemp = getLocationInput("backupHost");
	
	my $ret = undef;
	# setting up user backup location
	print $whiteSpace.CONST->{'SetBackupLoc'}.$lineFeed;
	if($backupHostTemp eq "") {
		$backupHost = `hostname`;
		chomp($backupHost);
		if($encType eq "DEFAULT") {
			$ret = setBackupLocation();
		} else {
					$ret =	1;
		}
	} else {
		if($defaultFolderExists eq 1){
			my $old_path = $backupHost;
			$backupHost = $backupHostTemp;
			$ret = renameBackLoc(\$old_path, \$backupHostTemp);
		}
		else{
			$backupHost = $backupHostTemp;
			$ret = setBackupLocation();
		}
	}
	
	if($ret eq 1|| $ret eq 2) {
		print $whiteSpace.CONST->{'BackupLocMsg'}.$whiteSpace."\"$backupHost\"".$lineFeed;
	}
	
	# create encode file for private key
	if($encType eq "PRIVATE") {
		createEncodeFile($pvt, $pvtPath);
	}
	
	while(1) {
		# get and set user restore location
		print $lineFeed.$whiteSpace.CONST->{'AskRestoreLoc'}.$lineFeed.$whiteSpace;
		$restoreLocation = getLocationInput("rloc");
		
		if( !-d $restoreLocation) {
			if( -f $restoreLocation or -l $restoreLocation or -p $restoreLocation or -S $restoreLocation or -b $restoreLocation or -c $restoreLocation or -t $restoreLocation) {
				print $whiteSpace.CONST->{'InvRestoreLoc'}.$whiteSpace."\"$restoreLocation\"".$lineFeed;
			} else {
				$confirmationChoice = undef;
				print $whiteSpace.CONST->{'DirCreateQuery'}.$lineFeed;
				getConfirmationChoice();
				if($confirmationChoice eq "Y" || $confirmationChoice eq "y") {
					#my $res = mkdir $restoreLocation;
					if(substr($restoreLocation, 0, 1) ne "/") {
						$restoreLocation = $usrProfileDir."/".$restoreLocation;
					}
					my $res = mkpath($restoreLocation);
					if($res ne 1) {
						print $whiteSpace.CONST->{'InvRestoreLoc'}."Reason: Permission denied to create directory: $restoreLocation\n";
					} else {
						chmod 0777, $restoreLocation;
						last
					} 	
				}
			}
		} else {
			if(substr($restoreLocation, -1, 1) ne "/") {
				$restoreLocation .= "/";
			}
			my $testPath = $restoreLocation."Idrivetest.txt";
			unless(open FILE, ">$testPath") {
				# Die with error message if we can't open it.
				#die " Unable to open :$testPath:. $!";
				print $whiteSpace.CONST->{'InvRestoreLoc'}."Reason: Permission denied to access: $restoreLocation\n";
			} else {
				last;
			}
			close FILE;
			my $res = unlink $testPath;
			#if($res ne 1) {
			#	print $whiteSpace.CONST->{'InvRestoreLoc'}."Reason: Permission denied to access: $restoreLocation\n";
			#} else {
			#	last;
			#}
		}
	}
	
	print $whiteSpace.CONST->{'RestoreLoc'}.$whiteSpace."\"$restoreLocation\"".$lineFeed;
	
	
	# get and set user restore from location
	getRestoreFromLoc(\$restoreHost);
	
	# get user email address
	print $lineFeed.$whiteSpace.CONST->{'AskEmailId'}.$lineFeed.$whiteSpace;
	
	my $wrongEmail = undef;
	while(1) {	
		my $failed =undef;
		my @email = undef;
		my $email = getInput();

		if($email =~ /\,|\;/) {
			@email = split(/\,|\;/, $email);
		} else {
			push(@email, $email);
		}
		
		@email = grep /\S/, @email;
		
		if(scalar(@email) lt 1) {
			print $whiteSpace.CONST->{'EmptyEmailId'}.$lineFeed.$lineFeed;
			print $whiteSpace.CONST->{'AskEmailId'}.$lineFeed.$whiteSpace;
			$wrongEmail = undef;
			next;
		}
		
		foreach my $eachId (@email) {
			my $tmp = quotemeta($eachId);
			if($emailAddr =~ /^$tmp$/) {
				next;
			}

			my $eVal = validEmailAddress($eachId);
			if($eVal eq 0 ) {
				$wrongEmail .=	"'".$eachId."' ";
				$failed = 1;
			} else {
				$emailAddr .= $eachId.",";
			}
		}

		if($failed ne 1) {
			last;
		} else {
			print $whiteSpace.CONST->{'InvalidEmail'}.$whiteSpace."\"$wrongEmail\"".$lineFeed.$lineFeed;
			print $whiteSpace.CONST->{'AskEmailId'}.$lineFeed.$whiteSpace;
			$wrongEmail = undef;
		}
	}
	
	# ask user for retain logs
	print $lineFeed.$whiteSpace.CONST->{'AskRetainLogs'}.$lineFeed;
	$confirmationChoice = undef;
	getConfirmationChoice();
	if($confirmationChoice eq "y" or $confirmationChoice eq "Y") {
		$ifRetainLogs = "YES";
	} else {
		$ifRetainLogs = "NO";
	}
	
	#ask user for Backup type
	print $whiteSpace."Please select Backup type".$lineFeed;
	print $whiteSpace.CONST->{'AskMirrorType'}.$lineFeed;
	print $whiteSpace.CONST->{'AskRelativeType'}.$lineFeed;
	$menuChoice = undef;
	getMenuChoice();
	if($menuChoice eq 1) {
		$backupType = "mirror";
	} elsif($menuChoice eq 2) {
		$backupType = "relative";
	}
}

#*********************************************************************************************
# Subroutine Name         : updateConfFile
# Objective               : update Configuration file based on user provided details.
# Added By                : Dhritikana
#*********************************************************************************************/
sub updateConfFile {
	my $dummyString = "XXXXX";
	
	print $whiteSpace.CONST->{'SetBackupList'};
	print $lineFeed.$whiteSpace.CONST->{'SetRestoreList'};
	print $lineFeed.$whiteSpace.CONST->{'SetFullExclList'};
	print $lineFeed.$whiteSpace.CONST->{'SetParExclList'};
	
	print $lineFeed.$lineFeed.$whiteSpace.CONST->{'AccountSet'}.$whiteSpace.CONST->{'AskLogin'}.$lineFeed;
	$confirmationChoice = undef;
	getConfirmationChoice();
	
	open CONF, ">", "$confFilePath" or print $tHandle "\n Couldn't write into file $confFilePath. Reason: $!\n" and die;
	chmod 0777, $confFilePath;
	my $confString	=	"USERNAME = $userName".$lineFeed;
	
	if($confirmationChoice eq "n" || $confirmationChoice eq "N") {
		unlink($pwdPath);
		if($encType eq "PRIVATE") {
			unlink($pvtPath);
		}
		
		$confString	.=	"PASSWORD = $pwd".$lineFeed.
						"PVTKEY = $pvt".$lineFeed;
	} else {
		# create password file for schedule jobs
		my $schPwdPath = $pwdPath."_SCH";
		copy($pwdPath, $schPwdPath);
		
		#create encoded password for sending email
		createEncodeSecondaryFile($pwd, $enPwdPath, $userName);

		$pvt = "";
		# create private key file for schedule jobs
		if($encType eq "PRIVATE") {
			my $schPvtPath = $pvtPath."_SCH";
			copy($pvtPath, $schPvtPath);
			$pvt = $dummyString;
		}
	
		$confString	.=	"PASSWORD = $dummyString".$lineFeed.
						"PVTKEY = $pvt".$lineFeed;
	}
	
	$confString	.=	"EMAILADDRESS = $emailAddr".$lineFeed.
					"BACKUPSETFILEPATH = ./BackupsetFile.txt".$lineFeed.
					"RESTORESETFILEPATH = ./RestoresetFile.txt".$lineFeed.
					"FULLEXCLUDELISTFILEPATH = ./FullExcludeList.txt".$lineFeed.
					"PARTIALEXCLUDELISTFILEPATH = ./PartialExcludeList.txt".$lineFeed.
					"REGEXEXCLUDEFILEPATH = ./RegexExcludeList.txt".$lineFeed.
					"RESTORELOCATION = $restoreLocation".$lineFeed.
					"BACKUPLOCATION = $backupHost".$lineFeed.
					"RESTOREFROM = $restoreHost".$lineFeed.
					"RETAINLOGS = $ifRetainLogs".$lineFeed.
					"PROXY = $proxyString".$lineFeed.
					"BWTHROTTLE = 100".$lineFeed.
					"BACKUPTYPE = $backupType";
					
	if($confirmationChoice eq "y" || $confirmationChoice eq "Y") {	
		createCache();		
		print $lineFeed.$whiteSpace.CONST->{'LoginSuccess'}.$lineFeed;
	}
			
	print CONF $confString;
	close CONF;
}
