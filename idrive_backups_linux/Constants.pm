#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

#use FindBin;
#use lib $FindBin::Bin;

my $conLib;
BEGIN {  $conLib = getcwd;  }
use lib $conLib;

package Constants;

#use base 'Exporter';

use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS );
BEGIN {
    @ISA = qw( Exporter );
    use Exporter;
}

use constant CONST => {		
		
		#------------------Menu Choice---------------------#
			AskDefAcc	=>	'1. Default encryption key',
			AskPvtAcc	=>	'2. Private encryption key',
			DisplayVer	=>	'1. Display versions of your file',
			BackupKillOp	=>	'1 -> KILL BACKUP JOB',
			RestoreKillOp	=>	'2 -> KILL RESTORE JOB',
			KillBothOprOp	=>	'3 -> KILL BOTH BACKUP AND RESTORE JOB',
			StatBackOp	=>	'1 -> BACKUP JOB',
			StatRstOp	=>	'2 -> RESTORE JOB',
			AskMirrorType	=> '1 -> mirror',
			AskRelativeType	=> '2 -> relative',
			
			
		#------------------ A -----------------------------#
			AskIfProxy	=>	'Are you using Proxy?(y/n)',
			AccountSet	=>	'Your Account is ready to use now.',
			LogoutSuccess	=>	'Account is logged out successfully',
			LoginAlready	=>	'Account is already logged in',
			AccCongiguringMsg	=>	'Account not set: Configuring the account...',
			LoginSuccess	=>	'Account is logged in successfully',
			AccLogin	=>	'account using login.pl and try again',
			AnotherRestoreJob => 'Another Restore job is in progress.',
			LogoutInfo => 'Account is already logged out.',
			
		#---------------------B -----------------------------#
			MkBackupDir	=>	'Backup location created successfully',
			BckupSchRunning	=>	'Backup_Script.pl: Scheduler job is running.',
			BckPathMissing	=>	'Backup set file path is missing in config file.',
			BckFileMissing	=>	'Backup set file not found, verify the config file parameters.',
			BckStartTm	=>	'Backup Start Time: ',
			BckEndTm	=>	'Backup End Time: ',
			BckUsrCancl	=>	'Backup failed. Reason: Operation cancelled by user.',
			BckCanclForChld	=>	'Backup failed. Reason: Operation cancelled.',
			BckContnt	=>	'Backupset content :',
			BeforeScript	=>	'before running this script',
			BothRunning	=>	'Both Schedule Backup and Schedule Restore Jobs are running',
			BackupSetEmpty => 'Backup set file is empty. ',
		
		#------------------- C ----------------------------#
			EvsCmplCheck	=>	'Checking for compatible idevsutil command line utility...',

			AskPvtAgain		=>	'confirm private encryption key again',
			ConfirmPvt		=>	'Confirming Private Key...OK',
			InputEmptyErr	=>	'Cannot be empty. Enter again.',
			CrtUserDir		=>	'Creating user name directory....',
			FileOpnErr	=>	'Could not open file ',
			FileCrtErr	=>	'Could not create ',
			ExcldMsg	=>	'considered to exclude from backup set, Reason : ',
			ForkErr	=>	'Cannot fork() child process : ',
			CrtEncFile	=>	'createEncodeFile :',
			ConfMissingErr	=>	'Configuration File does not exist.',
			CheckPreq	=>	'Checking Prerequisite...',
			CanContain => 'Username should contain a-z, 0-9 and underscore.',
			WrongCutOff => 'Scheduled time and cut off time should have minimum 5 minutes of difference.',
			CalCulate => 'Calculating..',
		
		#---------------------D -----------------------------#
			Instruct	=>	'Dear User, Please provide your details below',
			NotExist	=>	'does not exist.',
			AskRetainLogs	=>	'Do you want to retain logs?(y/n)',
			AskRestoreVer	=>	'Do you want to restore any specific version of file (y/n)?',
			PvtAccTypeMsg	=>	'Dear user, Your account type is PRIVATE',
			DefAccTypeMsg	=>	'Dear user, Your account type is DEFAULT.Ignoring and removing pvt-key from CONFIGURATION..',
			DirCrtMsg		=>	'User directory has been created successfully',
			AskLogin	=>	'Do you want to login?(y/n)',
		
		#---------------------E -----------------------------#
			AskUname	=>	'Enter your username :',
			AskPword	=>	'Enter your password :',
			AskProxyIp	=>	'Enter Proxy Server IP :',
			AskProxyPort	=>	'Enter Proxy Port :',
			AskProxyUname	=>	'Enter Proxy username if exists :',
			AskProxyPass	=>	'Enter Proxy password if exists :',
			EnterChoice		=>	'Enter your choice :',
			AskPvt		=>	'Enter your Private encryption key :',
			AskEmailId	=>	'Enter your e-mail ID(s) [For multiple e-mail IDs provide comma(,) or (;) seperation] :',
			AskBackupLoc	=>	'Enter your Backup Location :',
			AskRestoreLoc	=>	'Enter your Restore Location :',
			AskRestoreFrom	=>	'Enter your Restore From Location :',
			AskFilePath	=>	'Enter your File Path :',
			Exit	=>	'Exiting',
			AskOption	=> 'Enter Option :',
			ErrFlContnt	=>	'Error file content:',
			EmlIdMissing	=>	'Email address not provided in CONFIGURATION file.',
			EnterAgn	=> 'Enter Again : ',
			EvsChild => 'for EVS',
			LogChild => 'for Output Parsing',
			EmptyEmailId => 'Email address cannot be empty.',
			
		#------------------- F ----------------------------#
			FulExcld  => "full exclude= ",
			NotFound	=>	'File Not Found: ',
			GetSrvAdrErr	=>	'Failed to execute getServerAddress. Please check the credentials.',
			SendMailErr	=>	'Failed to send mail.',
			KilFail	=>	'Failed to kill ',
			CreateFail => 'Failed to create',
		
		#------------------- G ----------------------------#
			GetServAddr	=>	'getServerAddr : ',
			DirCreateQuery => 'Location doesn\'t exist. Do you want create?(y/n)',
		
		
		#------------------- H ----------------------------#
		
		#------------------- I ----------------------------#
			InvalidChoice	=>	'Invalid choice.',
			InvalidVersion	=>	'Invalid version.',
			EvsPermissionErr	=>	'idevsutil file does not have executable permission. Please give it executable permission',
			EvsMissingErr	=>	'idevsutil file does not exist in current directory. Please copy idevsutil file to current directory',
			InvalidUnamePwd	=>	'Invalid username or Password',
			InvalidEmail	=>	'Invalid email address',
			StatCount	=>	'In STATUS count : ',
			InvalidOp	=>	'invalid operation type.',
			NotRng	=>	'is not running.',
			IsRng	=>	'is running.',
			IsAbvl	=> 'is available',
			NoFileEvsMsg	=> 'Invalid restore from path. Reason: path does not exist.',
			StatSize	=> 'In Status size : ',
			InvLocInput	=> 'Invalid Location',
			InvUname	=> 'Invalid username. Please try again.',
			InvRestoreLoc => 'Invalid Restore Location : ',
			InvBackupLoc => 'Invalid Backup Loaction',
			InvRestoreFrom => 'Invalid Restore From',
			InvRetainLog	=> 'Invalid Retain Log option',
			InvProxy	=> 'Invalid proxy details',
		
		#------------------- J ----------------------------#
		
		
		#------------------- K ----------------------------#
			ProxyErr	=>	' Kindly verify your proxy details or check connectivity and try again.',
			ProxyUserErr	=> ' Kindly verify your proxy username & password and try again', 
		
		
		#------------------- L ----------------------------#
			
		#------------------- M ----------------------------#
		
		#------------------- N ----------------------------#
			NoOpRng	=>	'No Schedule Backup/Restore process is running.',
			BinNotFound	=> 'Not Found.',
			NotAbvl	=>	'is not available.',
			RstFromGuidMsg	=>	'Note: Your restore from location should indicate the location from which you want to restore the data.',
			NonExist => 'Invalid file path.',
		
		#------------------- O ----------------------------#
			OpUsrCancel	=>	'Operation could not be completed. Reason : Operation cancelled by User',
		
		
		#------------------- P ----------------------------#
			PvtErr	=>	'Private encryption key and confirm encryption key must be the same',
			AskPvtWithCond	=>	'Private Encryption key must contain 6 to 250 characters',
			TryAgain		=>	'Please Try Again',
			AskCorrectPvt	=>	'Invalid PVTKEY. Please try again.',
			NetworkErr	=>	'Probably your network has proxy settings or Server is down. Kindly Try Agin',
			AskVersion	=>	'Provide the version no for file.',
			AskPvtKey	=>	'Please provide your account Pvt-key in CONFIGURATION File',
			PlLogin	=>	'Please login to your',
			ParExcld	=>	'partial exclude= ',
			LoginWait	=> 'Please wait. Logging into your account...',
			SuggestInstall	=> 'Please install and try again.', 
			AskStatusOp	=>	'Please Choose one option to see Status',
			LongPwd => 'Parameter \'password\' should be at least 6 - 20 characters',
			ProvideEmailId	=>	'Provide your e-mail ID(s) [For multiple e-mail IDs provide comma(,) seperation]',
		
		
		#------------------- Q ----------------------------#
		
		
		#------------------- R ----------------------------#
			RestoreVer	=>	'2. Restore a Specific version of your file',
			RestoreOpStart	=>	'Restore operation has been started successfully. Please check the logs for more details.',
			PasswordEmptyErr	=>	'Required param: \'password\' not passed',
			BckupRetry	=>	'----Retrying to do Backup Operation--------',
			InstrctReadMe	=>	'Read "ReadMe.txt" for details.',
			ChldFailMsg	=>	'Reason : Child process launch failed.',
			AccUndrMntnc	=>	'Reason : Account is under maintenance.',
			AccCancld	=>	'Reason : Account is cancelled.',
			AccExprd	=>	'Reason : Account has expired.',
			NotRegFile	=>	' reason: Not a regular file/folder.',
			ParEXcldItem	=>	'  reason: Partial path excluded item.',
			FulExcldItem	=>	' reason: Full path excluded item.',
			RegexEXcldItem	=>	' reason: Regex path excluded item.',
			RstorSchRunning	=>	'Restore_Script.pl: Scheduler job is running.',
			RstPathMissing	=>	'Restore set file path is missing in config file.',
			RstFileMissing	=>	'Restore set file not found, verify the config file parameters',
			RstUsrCancl	=>	'Restore failed. Reason: Operation cancelled by user.',
			RstCanclForChld	=>	'Restore failed. Reason: Operation cancelled.',
			RstStartTm	=>	'Restore Start Time: ',
			RstEndTm	=>	'Restore End Time: ',
			RestoreSetEmpty => 'Restore set file is empty. ',
		
		#------------------- S ----------------------------#
			EvsInstSuccess	=>	'Successfully installed compatible idevsutil binary.',
			SetBackupLoc	=>	'Setting up your Backup Location...',
			SetBackupList	=>	'Setting up your Default Backupset File as BackupsetFile.txt...',
			SetRestoreList	=>	'Setting up your Default Restorset File as RestoresetFile.txt...',
			SetFullExclList	=>	'Setting up your Default Full Exclude list File as FullExcludeList.txt...',
			SetParExclList	=>	'Setting up your Default Partial Exclude list File as PartialExcludeList.txt...',
			Summary	=>	'Summary : ',
			KilSuccess	=>	'Successfully killed ',
			StatMissingErr => 'Status File doesn\'t exists',
		
		
		#------------------- T ----------------------------#
			TotalBckCnsdrdFile	=>	'Files considered for backup: ',
			TotalBckFile	=>	'Files backed up now: ',
			TotalSynFile	=>	'Files already present in your account: ',
			TotalBckFailFile	=>	'Files failed to backup: ',
			TotalRstCnsdFile	=>	'Files considered for restore: ',
			TotalRstFile	=>	'Files restored now: ',
			TotalRstFailFile	=>	'Files failed to restore: ',
			TestOk	=>	'Tested ok',
			

		
		
		#------------------- U ----------------------------#
			EvsMatchError	=> 'unable to get compatible idevsutil binary.',
			LogoutErr	=>	'Unable to logout from account. Please try again',
			MkDirErr	=>	'Unable to create user directory : ',
			DoBckOpErr	=>	'Unable to proceed the backup operation',
			DoRstOpErr	=>	'Unable to proceed the restore operation',
			BckFileOpnErr	=>	'Unable to open Backup set file',
			ExclFileOpnErr	=>	'Unable to open full path exclude file',
			ParExclFileOpnErr	=>	'Unable to open partial path exclude file',
			ExclFileOpnErr	=>	'Unable to open exclude file',
			unzipErr	=>	'Unable to use unzip. Please reinstall "unzip" and try again.',
			curlErr	=>	'Unable to use curl. Please reinstall "curl" and try again.',
			BackLocCrFailMsg =>	'Unable to Create Backup Location. Please try again.',
			ForkErr => 'Unable to start child process',  
			bckProcessFailureMsg => 'Unable to proceed the backup operation. Reason : Child process launch failed for monitoring output file.',
			rstProcessFailureMsg => 'Unable to proceed the restore operation. Reason : Child process launch failed for monitoring output file.',
			CronQuery => ' Unable to update cron. Please provide root ',
			
		#------------------- V ----------------------------#
			verifyPvt	=>	'Verifying your Private encryption key...',
			verifiedPvt	=>	'Verified Private encryption key...OK',
			verifyAccount	=>	'Verifying your account information...',
		
		
		#------------------- W ----------------------------#
			WrongBackupType => 'Incorrect Backup type in CONFIGURATION_FILE. Please provide mirror/relative and try again.',
		
		
		#------------------- X ----------------------------#
		
		
		#------------------- Y ----------------------------#
			AskConfig	=> 'Your Account is not configured. Do you want to configure it?(y/n)',
			BackupLocMsg	=>	'Your backup location is set to',
			RestoreLocMsg	=>	'Your restore from location is set to',
			RestoreLoc	=>	'Your restore location is set to',
		
		#------------------- Z ----------------------------#
		
};
our @EXPORT_OK = ('CONST');

1;
		
