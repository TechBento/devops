#!/usr/bin/perl

require 'header.pl';
use Constants 'CONST';

my $CurrentUser = getCurrentUser();

#if the current user dir doesn't exists
$usrProfileDir = "$usrProfilePath/$CurrentUser";
if($CurrentUser ne "" && -d $usrProfileDir) {
	$pwdPath = "$usrProfilePath/$CurrentUser/.IDPWD";
	$pvtPath = "$usrProfilePath/$CurrentUser/.IDPVT";
}

if(unlink($pwdPath)) {
	unlink $userTxt;
	clearFields("PASSWORD");

	if(unlink($pvtPath)) {
		clearFields("PVTKEY");
	}
	if(${ARGV[0]} ne 1) {
		print CONST->{'LogoutSuccess'}.$lineFeed;
	}
}
else {
	if(${ARGV[0]} ne 1){
		if($! =~ /No such file or directory/) {
			print CONST->{'LogoutInfo'}.$lineFeed;
		} else {
			print $lineFeed.CONST->{'LogoutErr'}."$!".$lineFeed;
		}
	}
	else{
		if(unlink($pvtPath)) {
	        	clearFields("PVTKEY");
		}
	}	
}

sub clearFields() 
{
	$dummyString = "";
	$confField = $_[0];
	putParameterValue(\$confField, \$dummyString);
}
