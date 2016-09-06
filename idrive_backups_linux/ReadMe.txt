								IDrive for Linux
								=================

I. INTRODUCTION
================

This is a script-based approach to backup/restore your Linux/Unix server with minimal scripting. 

II. Perform below steps, to proceed with script execution for backup / restore
==============================================================================

STEP	1: Create an IDrive online account via www.idrive.com   
STEP	2: The script bundle can be downloaded from the link "https://www.idrive.com/downloads/linux/download-for-linux/IDrive_for_Linux.zip".
    After downloading, extract the zip file in your machine. Current unzipped folder ie IDrive_for_Linux should contain below listed files.
          				
			a. Account_Setting.pl
			b. login.pl
			c. Backup_Script.pl
			d. Restore_Script.pl
			e. Scheduler_Script.pl
			f. Job_Termination_Script.pl
			g. Status_Retrieval_Script.pl
			h. Restore_Version.pl
			i. header.pl
			j. logout.pl
			k. CONFIGURATION_FILE
			l. BackupsetFile.txt
			m. RestoresetFile.txt
			n. FullExcludeList.txt
			o. PartialExcludeList.txt
			p. RegexExcludeList.txt
			q. Constants.pm
	
STEP 	3: Provide appropriate permissions (executable permission) to the scripts
		Example:  chmod a+x *.pl
			
STEP	4: Package Setup
		To set up the script package locally with your IDrive account, run the following command and follow the instructions.
		$./Account_Settings.pl
	   
		if there is trouble running Account_Setting.pl, please do the below steps to set up IDrive account manually:
   
			a. Download the command line utility: idevsutil (32 bit / 64 bit) manually from 
			  http://evs.idrive.com/download.htm and place it inside the script folder (extracted folder) 
			b. chmod a+x idevsutil
			c.	Configure file settings for backup/restore. 
	
		The "CONFIGURATION_FILE" is provided along with the download bundle. The following are the 
		parameters that you need to set. 
		
		USERNAME : Your IDrive account username. (This is a mandatory field)
					Example:  USERNAME = <your account username>
		
		PASSWORD : Your IDrive account password. (This is a mandatory field)
					Example:  PASSWORD = <your account password>
		
		PVTKEY   : Enter your private encryption key.
					Example:  PVTKEY = <myprivate-encryption-key>
					Keep it blank if your account is Default.
		
		EMAILADDRESS : Enter your valid email-address to receive the backup/restore job status 
					  (email notification)
		
					Example:  EMAILADDRESS = sample@test.com 
					To get notification on multiple mail-addresses, Enter your valid 
					email-addresses sperated by comma.
				
					Example:  EMAILADDRESS = sample1@test.com, sample2@test.com, sample3@test.com
					If the scheduled backup email notification is identified as spam then add  
					IDrive as a safe sender (link: https://www.idrive.com/white_list.htm).
		
		BACKUPSETFILEPATH : Enter the backup set file path.
					Note: Enter file / folder paths that you wish to backup into 
					backup set file.
					Example:  BACKUPSETFILEPATH = ./BackupsetFile.txt
	
		RESTORESETFILEPATH : Enter the restore set file path.
					Note: Enter file / folder paths that you wish to restore into 
					restore set file.
					Example:  RESTORESETFILEPATH = ./RestoresetFile.txt
		
		FULLEXCLUDELISTFILEPATH : Enter the full exclude list file path.
		
					Note: Enter file / folder paths that you wish to exclude from back up in exclude list file. 
					If you have provided a folder path in backup set file, but wish to exclude certain sub-folders/files from backup, 
					you can provide the absolute path of those sub-folders / files in exclude list file.
		
					Please leave the exclude list file blank in case you don't
					need to exclude folders / files from getting backed up
		
					Example:  EXCLUDELISTFILEPATH = ./FullExcludeList.txt
					Your Backupset contains /home/FolderA and if you want to exclude /home/FolderA/junk, write this folder path
					ie: /home/FolderA/junk in FullExcludeList.txt.
					
							 
		PARTIALEXCLUDELISTFILEPATH : Enter the partial exclude list file path.
					You can exclude files/folders based on their partial names from backup.

					Enter a part of the file/folder name in the partial exclude list file path to exclude the entries with that name.
					Keep the partial exclude list file path blank, if you do not want any files/folders to exclude from backup.

		
					Example:  PARTIALEXCLUDELISTFILEPATH = ./PartialExcludeList.txt
					Your Backupset contains /home/FolderA and if you want to exclude all the junk folders/files as 
					/home/FolderA/junk, /home/FolderA/junk01, /home/FolderA/junk03 etc then
					write "junk" in PartialExcludeList.txt.
					
		REGEXEXCLUDELISTFILEPATH : Enter the regex exclude list file path.
					You can exclude files/folders based on regex pattern from backup.
					
					Enter a regex that maches file/folder name in regex exclude list file path to exclude.
					Keep the regex exclude list file path blank, if you do not want any files/folders to exclude from backup.
		
					Example:  REGEXEXCLUDELISTFILEPATH = ./RegexExcludeList.txt
					Your Backupset contains /home/Folder01 , /home/Folder02, /home/FolderA, /home/FolderB.
					if you want to exclude all folders/files that contains numeric values in name ie
					/home/Folder01, /home/Folder02 then write \d+ in RegexExcludeList.txt.
					
		
		RESTORELOCATION : The location on the local computer where the files / folders will be restored. 

					Example: RESTORELOCATION = /home/
		
		BACKUPLOCATION :  The hostname of local machine will be considered by default for this field. 
					User can customize this field to backup data. All the backed up files/folders 
					in the server will be under this name. If the machine/account is changed, 
					this field can also be changed to continue to use the same previous 
					BACKUPLOCATION of the backup in User's account.
				
					Note: In case this field left empty then machine name will be considered.
		
		RESTOREFROM : The hostname of local machine will be considered by default for this field.    
					User can customize this field to restore data. Any files/folders that are 
					to be restored from the server to local machine should be under this name.
					  
					Note: In case this field left empty then machine name will be considered.
		
		RETAINLOGS : Enter YES/NO for this field. If YES, then all the LOGS generated will be 
					retained as-is. If NO, then all the LOGS that were generated so far will be
					cleared except the current running job. The deletion of LOGS is done automatically when
					a new job runs. YES is considered if this field is left empty.
		
		PROXY	: Provide your proxy details,if your machine is behind proxy server. 
					PROXY = <Username>:<Password>@<IPAddress>:<Port>
					Provide all field Username, Password, IPAddress and Port empty in case no proxy is set 
					in your machine. For Ex: PROXY = :@:
		  
		BWTHROTTLE : Enter bandwidth throttle value between 1 and 100 for restricting bandwidth usage for backup.
					Example: BWTHROTTLE = 75
					75% of available bandwidth will be used for backup. By default, the bandwidth throttle value is set at 100%.
		
		Note: For more information, verify the sample configuration and other supported files provided along with the download bundle.
		

step	5: Login to your IDrive Account

		Once after setting the configuration file (as detailed above), run the below command if you have not logged in using Account_Setting.pl while setting up the account
		locally.
		$./login.pl
		
		This perl will create a logged in session for the IDrive Account mentioned in configuration file.
		Also it will replace your IDrive password and private key values in configuration file with dummy values
		after successful login.

step	6. Schedule the backup/restore job

		Once after setting the configuration file (as detailed above), run the below command
		$./Scheduler_Script.pl
		
		Choose the desired scheduled date/time for the backup/restore job. 
		The backup/restore job will automatically start at the scheduled time.
		Now you can even schedule cut off to cancel the running job at a specific time.

step 	7. View the backup/restore progress 

		To view the progress details during backup/restore, run the below command 
		$./Status_Retrieval_Script.pl

step    8. Restore

		Run the restore script using the below command 
		$./Restore_Script.pl
       
step	9. View file versions and Restore
    
		To view the list of all available versions for a file or to restore any previous version of file, 
		run the following command
		$./Restore_Version.pl

step	10. View the backup / restore logs
 
		You can view the backup / restore log files that are present in the ./user_profile/<UserName>/<Backup/Restore>/<Manual/Scheduled>/LOGS folder.
		Example: For Manual Backup for user "samuel" the log path will be ./user_profile/samuel/Backup/Manual/Scheduled/LOGS

step	11. Logout from your IDrive Account
	
		Run $./logout.pl
		In case you want to keep your IDrive account more safe then you can use this script to log out from 
		your logged in session. 
		
		Once you log out, your IDrive account password and private key values will become empty in configuration file.
		This will make your account more secure as no one can see your credentials and no one can access your account even 
		using scripts. 
		
		For accessing IDrive account again, password and private key needs to mention in configuration file and need to run login.pl.
    

III. Script file details
========================
	
	a. Account_Setting.pl
	
	Run/execute this script to set CONFIGURATION_FILE without modifying it manually.
	
	b. login.pl
	
	Mandatory script to be executed before performing any other operations to login to your IDrive account.
	
	c. Scheduler_Script.pl
	
	Scheduler_Script.pl is used to schedule the backup/restore job periodically. The backup job
	will automatically start at the scheduled time.
	  
	Using this script, you can also edit and delete the existing backup/restore job.
	
	d. Backup_Script.pl
	
	The script will be automatically executed during backup operation.
	
	e. Status_Retrieval_Script.pl
	
	Run/execute this script to view the progress details of the schedule backup/restore job which is underway. 
	
	f. Job_Termination_Script.pl
	
	Run/execute this script to stop / terminate the backup/restore job which is underway.
	
	g. Restore_Script.pl
	
	Run/execute this script to restore files / folders to your local computer. Ensure that the restore set file path is configured in the CONFIGURATION_FILE (refer the above section (4) for more details on configuration file settings)
	
	h. Restore_Version.pl
	
	Run/execute this script to view/restore a specific version of your backed up file.
	
	i. header.pl
	
	The script will be automatically executed during backup and restore operation.
	
	j. logout.pl
	
	Optional script when executed will log out from logged in IDrive account and clear PASSWORD and PVTKEY fields in CONFIGURATION_FILE. 
	
	User has to run login.pl again to create a logged in session and to run scripts for any other operations.
	
	Note: Scheduled jobs will run even after logging out from IDrive account using logout.pl.


IV. SYSTEM REQUIREMENTS
=======================
    Linux(CentOS/Ubuntu/Fedora) - 32-bit/64-bit

V. SOFTWARE/PLUG-IN DOWNLOADS
=============================
   Perl v5.8 or later
   Get the Perl version details using the command : $perl -v 

VI. RELEASES
=============
	Build 1.0:
		N/A
	
	Build 1.1:
	
		1.	Fixed the backup/restore issue for password having special characters.
		2.	Fixed the backup/restore issue for encryption key having special characters.
		3.	Fixed the backup/restore issue for user name having special characters.
		4.	Fixed the backup/restore issue for backup/restore location name having special characters.
		5.	Moved LOGS folder inside user name folder for better management.
		6.	Avoided unnecessary calls to server at the time of backup as well as restore. 
			Like create directory call, get server call and config account call. As before these calls 
			was taking place with each backup and restore operation.
		7.	New file named header.pl has been created. It contains all common functionalities. 

	Build 1.2:
		
		1.	Avoided error in the log when email is not specified in CONFIGURATION_FILE after backup 
			operation.
		2.	A new BACKUPLOCATION field has been introduced in CONFIGURATION_FILE. All the backed up 
			files/folders will be stored in the server under this name.  
		3.	A new RESTOREFROM field has been introduced in CONFIGURATION_FILE.  Any files/folders 
			that exist under this name can be restored from server to local machine.

	Build 1.3:

		1.	A new field RETAINLOGS has been introduced in CONFIGURATION_FILE. This field is used to 
			determine if all the logs in LOGS folder have to be maintained or not.
		2.	Fixed Retry attempt issue if backup/restore is interrupted for certain reasons.  

	Build 1.4:

		1. 	A new field PROXY has been introduced in CONFIGURATION_FILE. This field if enabled will 
			perform operations such as Backup/Restore via specified Proxy IP address.
		2. 	A new file login.pl has been introduced which reads required parameters from CONFIGURATION_FILE
			and validates IDrive credentials and create a logged in session. 
		3. 	A new file logout.pl has been introduced which allow to log out from logged in session for IDrive account.
		      It also clears PASSWORD and PVTKEY fields in configuration file.
	Build 1.5:
		1. 	A new field BWTHROTTLE has been introduced in CONFIGURATION_FILE. To restrict the bandwidth usage
		   for backup operation.
		2. 	Changes has been made to make script work on perl ver 5.8 as well.

	Build 1.6:
		1.	Schedule backup issue has been fixed in user logged out mode.

	Build 1.7:
		1. 	Support for multiple email notification on Schedule Backup has been implemented.
		2.	ENC TYPE has been removed from CONFIGURATION File.
		3. 	Schedule for Restore job has been implemented.
		4. 	Fixed login and logout issue. 

	Build 1.8:
		1. 	Support for multiple email notification on Schedule Restore has been implemented.
		2. 	Scheduler Script is enhanced to perform schedule Restore job.
		3.	Schedule restore is enhanced to run even after logout as well.
		4. 	Status retrieval support for manual as well as scheduled restore job has been implemented. 
		5. 	Job termination script is enhanced to cancel ongoing backup or restore or both the job.
		6.	Fixed issue of deleting backup or restore set file.
		7. 	Showing of Exclude items on Log is implemented.
		8.	Login is enhanced to display certain error messages. 
		
	Build 1.9:
		1.	Partial Exclude has been implemented.
		2.	Added support of "cut off feature".
		3.	A new script "Restore_Version.pl" has been introduced to view/restore previous versions of a file.
		4.	A new script "Account_Setting.pl" has been introduced to setup user account locally.
		5.	Fixed login issue with wrong encryption key.
		6.	Fixed issue of skipping backup for hidden files.
		7.	Fixed the issue of retaining logs for "NO" option in some scenarios.
		8.	A new module called "Constants.pm" has been introduced to hold all display messages.
		9.	Full exclude issue has been fixed.
		10.	Enhanced logs for backup/restore for displaying machine name,Backup/Restore Location and backup/restore type like full backup or incremental backup.
		11.	Fixed the issue with sending e-mail under proxy settings.
		12.	Added script working folder as exclude entry for full path exclude to avoid any backup issue.
		13.	Fixed the issue of not deleting wrong password/private-key path during login.
		
	Build 2.0
		1.	operations.pl is introduced for centralizing some key operations.
		2. 	Replaced threads with fork processes.
		3.	Memory fixes for Backup and Restore processes.
		4.	Provided better Progress Details for manual and schedule job with size and transfer rate fields.
		5.	User logs has been enhanced for better understanding.
		6.	Removal of all downloaded zip and unzipped files after getting compatible binary in Account Setting pl
		7.	Avoided removing of trace log in failure cases in Account Setting pl.
		8.	Restricted user to provide backup location as "/".
		9.	Fixed for special character issue.
		10.	Fixed login issue when user tries to login without updating default configuration file.
		11.	Fixed the issue in Account setting pl for wrong proxy details.
		12.	Fixed the issue of not showing send mail error due to invalid email address in user log in case of manual configuration.
		13.	Removed FindBin dependency in Constants module.
		14. Fixed issue of user given invalid restore location in Account_Setting.pl.
		
	Build 2.1
		1. Modified Scheduler script to prompt for "Daily or Weekly" options for user to schedule job.
		2. User given Restore Location is created newly if not available by Account setting pl.
		3. Error message diplay if Backupset/Restore set file is empty.
		4. Fixed the issue of not allowing user to login when another user logged in.
		5. Fixed the issue of folder/file creation/access which is having special character.
		6. Fixed permission issue while accessing from upper level user.
		
	Build 2.2
		1. Enhanched Backup and Restore for better performance.
		2. Parallel Manual and Schedule Backup/Restore implementation.
		3. Better user log with failed files information.
		4. Provision of both mirror and relative Backup.
		5. Email address mandatory and semicolon (;) sepeartion is also allowed.
		6. Cancellation of individual Manual/Schedule job is implemented via Job_Termination_Script.pl.
		
	Build 2.3
		1. Fixed Scheduler script issue for ubuntu machine.
		
	Build 2.4
		1. Fixed issue related to symlink exclude during Backup.
		2. Updated new idevsutil links.
	======================================================================================
