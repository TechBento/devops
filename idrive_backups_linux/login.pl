#!/usr/bin/perl
require 'header.pl';
use File::Path;
use File::Copy;
use Constants 'CONST';

#Configuration File Path#
my $isPrivate = 0;
my $encType = undef;
my $NotLoggedIn = 0;

#Checking Congiguration file Pararmeters
checkConfParams();

#Check EVS Binary 
my $err_string = checkBinaryExists();
if($err_string ne "") {
	print $err_string;
	exit 1;
}
	
#Get Previous username
my $CurrentUser = getCurrentUser();

if($CurrentUser ne $userName) {
	my $TmpPwdPath = "$usrProfilePath/$CurrentUser/.IDPWD";
	if( -e $TmpPwdPath and -f $TmpPwdPath) {
		print "User \"$CurrentUser\" is already logged in. Please logout and try again.".$lineFeed;
		exit 1;
	}
}
#Need Review 
#if($CurrentUser eq ""){
	#$NotLoggedIn = 1;
#}

#Creating User Directory
createUserDir();

# Trace Log Entry #
my $curFile = basename(__FILE__);
print $tHandle "$lineFeed File: $curFile $lineFeed",
		"---------------------------------------- $lineFeed";

unless(-e $pwdPath) {
	getParameterValue(\"PASSWORD", \$hashParameters{PASSWORD});
	if(!$hashParameters{PASSWORD} or $hashParameters{PASSWORD} eq "") {
		print CONST->{'PasswordEmptyErr'}.$lineFeed;
		exit;
	}
	if(length($hashParameters{PASSWORD}) > 20) {
		print CONST->{'LongPwd'}.$lineFeed;
		exit;
	}
	createEncodeFile($hashParameters{PASSWORD}, $pwdPath);
	$NotLoggedIn = 1;
}

unless(-e $enPwdPath) {
	getParameterValue(\"PASSWORD", \$hashParameters{PASSWORD});
	createEncodeSecondaryFile($hashParameters{PASSWORD}, $enPwdPath, $userName);
}

if($NotLoggedIn) {
	validateAccount();
}
else {
	print CONST->{'LoginAlready'}.$lineFeed;
	exit;
}

#****************************************************************************************************
# Subroutine Name         : checkBinaryExists.
# Objective               : This subroutine checks for the existence of idevsutil binary in the
#							current directory and also if the binary has executable permission.
# Added By                : 
#*****************************************************************************************************/
sub checkBinaryExists()
{
  	$workingDir = $currentDir;
  	
  	my $binaryPath = "$workingDir"."/idevsutil";

  	if(-f $binaryPath and !-x $binaryPath)
  	{
			print CONST->{'EvsPermissionErr'}.$lineFeed;
    		exit 1;
  	}
  	elsif(!-f $binaryPath)
  	{
			print CONST->{'EvsMissingErr'}.$lineFeed;
    		exit 1;
  	}
  	else {
  	}
}

#****************************************************************************************************
# Subroutine Name         : validateAccount.
# Objective               : This subroutine validates an user account if the account is
#							private or default. It configues the previously not set Account.
# Added By                : 
#*****************************************************************************************************/
sub validateAccount()
{
	my $ifEmpty = undef;
	getParameterValue(\"PVTKEY", \$hashParameters{PVTKEY});
	chomp($hashParameters{PVTKEY});
	if(!defined $hashParameters{PVTKEY} or 
		$hashParameters{PVTKEY} eq "") {
		$ifEmpty = 1;
	} 
	elsif ($hashParameters{PVTKEY} ne "") {
		$ifEmpty = 0;
	}
	
	my $validateUtf8File = getOperationFile($validateOp);
	chomp($validateUtf8File);

	#log API in trace file as well
	print $tHandle "$lineFeed validateAccount: ";
	$validateUtf8File =~ s/\'/\'\\''/g;
	
	my $idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$validateUtf8File."'".$whiteSpace.$errorRedirection;
	my $commandOutput = `$idevsutilCommandLine`;
	
	print $tHandle "$lineFeed $commandOutput $lineFeed";
	unlink $validateUtf8File;

	if($commandOutput =~ m/configstatus\=\"NOT SET\"/i) { 
		print $whiteSpace.CONST->{'AccCongiguringMsg'}.$lineFeed;
		configureAccount();
	}
	elsif($commandOutput =~ m/configtype\=\"PRIVATE\"/i && $ifEmpty eq 1) {
		print CONST->{'PvtAccTypeMsg'}.$lineFeed;
		print CONST->{'AskPvtKey'}.$lineFeed;
		if(-e $enPwdPath){
			unlink($enPwdPath);
		}
		if(-e $pwdPath){
			unlink($pwdPath);
		}
		exit;
	}
	elsif($commandOutput =~ m/configtype\=\"DEFAULT\"/i && $ifEmpty eq 0) {
		print $whiteSpace.CONST->{'DefAccTypeMsg'}.$lineFeed;
		$encType = $defaultEncryptionKey;
		putParameterValue(\"PVTKEY", "");
	}
	elsif($commandOutput =~ m/configtype\=\"PRIVATE\"/i && $ifEmpty eq 0) {
		$encType = $privateEncryptionKey;
		$isPrivate = 1;
	}
	elsif($commandOutput =~ m/configtype\=\"DEFAULT\"/i && $ifEmpty eq 1) {
		$encType = $defaultEncryptionKey;
	}
	elsif($commandOutput =~ m/desc\=\"Invalid username or Password\"|desc\=\"Parameter 'password' too short\"/) {
		print CONST->{'InvalidUnamePwd'}.$lineFeed;
		if(-e $enPwdPath){
			unlink($enPwdPath);
		}
		if(-e $pwdPath){		
			unlink($pwdPath);
		}
		exit;
	} elsif($commandOutput =~ m/bad response from proxy/) {
		print CONST->{'InvProxy'}.$lineFeed;
		if(-e $enPwdPath){
			unlink($enPwdPath);
		}
		if(-e $pwdPath){		
			unlink($pwdPath);
		}
		exit;
	} else {
		print $lineFeed.$commandOutput.$lineFeed;
	}
	verifyAccount();
}

#****************************************************************************************************
# Subroutine Name         : configureAccount.
# Objective               : This subroutine configures an user account if the 
#							account is not already configured.
# Added By                : 
#*****************************************************************************************************/
sub configureAccount() {
	if(! -f $pvtPath) {
		createEncodeFile($hashParameters{PVTKEY}, $pvtPath);
	}
		
	#--------------------------------------------------------------
	print $tHandle "$lineFeed configureAccount: ";
	
	my $configUtf8File = getOperationFile($configOp, $encType);
	chomp($configUtf8File);
	$configUtf8File =~ s/\'/\'\\''/g;
	
	$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$configUtf8File."'".$whiteSpace.$errorRedirection;
	my $commandOutput = `$idevsutilCommandLine`;
	print $tHandle "$lineFeed $commandOutput $lineFeed";
	unlink $configUtf8File;
	#--------------------------------------------------------------
}

#****************************************************************************************************
# Subroutine Name         : verifyAccount.
# Objective               : This subroutine varifies the encryption key by creating Folder.
# Added By                : Dhritikana
#*****************************************************************************************************/
sub verifyAccount()
{
		if(! -f $pvtPath && $hashParameters{PVTKEY} ne "") {
			createEncodeFile($hashParameters{PVTKEY}, $pvtPath);
		}
		
		#get evs server address for other APIs
		getServerAddr();
		
		my $createDirUtfFile = getOperationFile($createDirOp, $encType);
		$createDirUtfFile =~ s/\'/\'\\''/g;
		$idevsutilCommandLine = $idevsutilBinaryPath.$whiteSpace.$idevsutilArgument.$assignmentOperator."'".$createDirUtfFile."'".$whiteSpace.$errorRedirection;
		$commandOutput = `$idevsutilCommandLine`;

		unlink($createDirUtfFile);
		if($commandOutput =~ /encryption verification failed|key must be between 4 and 256/) {
			print CONST->{'AskCorrectPvt'}.$lineFeed;
			unlink($pwdPath);
			unlink($pvtPath);
			unlink($pvtPath."_SCH");
		} 
		elsif($commandOutput =~ /created successfull|file or folder exists/) {
			print $lineFeed.$whiteSpace.CONST->{'LoginSuccess'}.$lineFeed;
			#Create Cache Directory 
			createCache();
			updateConf();
		} 
		else {
			print $tHandle "$commandOutput.$lineFeed";			
			if(-e $pvtPath) {
				unlink($pvtPath);
				unlink($pvtPath."_SCH");
			}
		}
}

#****************************************************************************************************
# Subroutine Name         : updateConf.
# Objective               : This subroutine updates the Configuration file with account config status
#							and creates path for schedule Backup/Restore job.
# Added By                : 
#*****************************************************************************************************/
sub updateConf()
{
	$dummyString = "XXXXX";
	$schPwdPath = "$pwdPath"."_SCH";
	copy($pwdPath, $schPwdPath);
	putParameterValue(\"PASSWORD", \$dummyString);
	if($isPrivate) {
		$schPvtPath = $pvtPath."_SCH";
		copy($pvtPath, $schPvtPath);
		putParameterValue(\"PVTKEY", \$dummyString);	
	}
}

#****************************************************************************************************
# Subroutine Name         : checkConfParams.
# Objective               : This subroutine exits if the CONFIGURATION file is not edited.
# Added By                : Dhritikana
#*****************************************************************************************************/
sub checkConfParams{
	if($userName eq "<your IDrive account user name>") {
		print CONST->{'InvUname'}.$lineFeed;
		exit 1;
	}
	
	getParameterValue(\"PASSWORD", \$hashParameters{PASSWORD});
	if(!$hashParameters{PASSWORD} or $hashParameters{PASSWORD} eq "") {
		print CONST->{'PasswordEmptyErr'}.$lineFeed;
		exit;
	}
	
	if($restoreLocation eq "<location in your machine where data needs to be restored>") {
		print CONST->{'InvRestoreLoc'}.$lineFeed;
		exit 1;
	}
	if($backupHost eq "<location in your IDrive account where data needs to be backed up>") {
		print CONST->{'InvBackupLoc'}.$lineFeed;
		exit 1;
	}
	if($restoreHost =~ /\<location in your IDrive account from where data needs to be restored/) {
		print CONST->{'InvRestoreFrom'}.$lineFeed;
		exit 1;
	}
	if($ifRetainLogs eq "<YES/NO>") {
		print CONST->{'InvRetainLog'}.$lineFeed;
		exit 1;
	}
	if($proxyStr eq "<PROXY USER>:<PROXY PASSWORD>@<PROXY IP>:<PROXY PORT>") {
		print CONST->{'InvProxy'}.$lineFeed;
		exit 1;
	}
	
	if(substr($configEmailAddress, -1) eq ";" or substr($configEmailAddress, -1) eq ",") {
		chop($configEmailAddress);
	}
	
	if($configEmailAddress =~ /\,|\;/) {
		@email = split(/\,|\;/, $configEmailAddress);
	} else {
		push(@email, $configEmailAddress);
	}
	@email = grep /\S/, @email;
	
	if(scalar(@email) lt 1) {
		print $lineFeed.$whiteSpace.CONST->{'EmlIdMissing'}.$lineFeed;
		print $whiteSpace.CONST->{'ProvideEmailId'}.$lineFeed.$whiteSpace;
		exit 1;
	}
	
	if(!backupTypeCheck()) {
		exit(1);
	}
}
