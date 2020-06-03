#!/usr/bin/perl
## Author: Dariusz Zielinski-Kolasinski
## Licence: GPL
## Version: 1.0 (2020-06-03)
##
## This is HPE OfficeConnect Switch 1920S 8G JL380A startup-configuration download script
## Tested with PD.02.12 firmware
##


use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Term::ANSIColor qw(:constants);

### INPUT
if ($#ARGV != 3) {
	print "Usage: $0 <ip/hostname> <user> <pass> <output filename>\n";
	exit(1);
}

### VALIDATE INPUT
my $username = $ARGV[1];
my $password = $ARGV[2];
my $host = $ARGV[0];
my $filename = $ARGV[3];

unless ($host =~ /^[0-9a-zA-Z\.\-]+$/) {
	print RED,"IP/Hostname - input does not match pattern!\n",RESET;
	exit(1);
}

### INIT
my $cookie_jar = HTTP::Cookies->new( );
my $ua = LWP::UserAgent->new;

$ua->cookie_jar( $cookie_jar );


### LOGIN REQUEST
my $req = POST 'http://'.$host.'/htdocs/login/login.lua', [ 
	'username' => $username,
	'password' => $password
]; 

my $resp = $ua->request( $req );

if ($resp->is_success) {
	if (index($resp->content, '"error": ""') == -1) {
		print RED,"LOGIN OK, BUT ERROR FOUND, RESPONSE: ",RESET,$resp->content,"\n";
		logout($ua, 1);
	} else {
		print GREEN,"LOGIN OK\n",.RESET;
	}
} else {
	print RED,"LOGIN ERROR: ", RESET, $resp->status_line,"\n";
	logout($ua, 1);
}

### DOWNLOAD REQUEST
my $token = time().'000';

$req = POST 'http://'.$host.'/htdocs/lua/ajax/file_upload_ajax.lua?protocol=6', [ 
	'file_type_sel[]'=> 'config',
	'http_token'=> $token,
	'protocol' => '6'
]; 

$resp = $ua->request( $req );
my $params = '';
if ($resp->is_success) {
	if ( $resp->content =~ /"queryParams": "([^"]+)", "successful": "ready", "errorMsgs": ""/) { # "
		$params = $1;
		print GREEN,"REQ FILE OK, params: ",RESET,$params,"\n";
	} else {
		print RED,"REQ FILE OK, BUT ERROR FOUND",RESET,$resp->content,"\n";
		logout($ua, 1);
	}
} else {
	print RED,"REQ FILE ERROR: ",RESET, $resp->status_line,"\n";
	logout($ua, 1);
}

### DOWNLOAD
$req = GET 'http://'.$host.'/htdocs/pages/base/file_http_download.lsp'.$params; 

$resp = $ua->request( $req );

if ($resp->is_success) {
	print GREEN,"DOWNLOAD OK\n",RESET;
	open(FD, ">$filename") || die "Can`t open: $filename: $!\n";
	print FD $resp->content;
	close(FD);
} else {
	print RED,"DOWNLOAD ERROR: ",RESET, $resp->status_line,"\n";
	logout($ua, 1);
}

### CLEANUP AFTER DOWNLOAD
$req = GET 'http://'.$host.'/htdocs/pages/base/file_http_download.lsp'.$params.'&remove=true'; 

$resp = $ua->request( $req );

if ($resp->is_success) {
	print GREEN,"CLEANUP OK\n",RESET;
} else {
	print YELLOW,"CLEANUP ERROR: ",RESET, $resp->status_line,"\n";
	logout($ua, 1);
}

logout($ua, 0);

### LOGOUT FUNCTION
sub logout
{
	my $ua = shift;
	my $fail = shift;

	$req = POST 'http://'.$host.'/htdocs/pages/main/logout.lsp', []; 
	$resp = $ua->request( $req );
	if ($resp->is_success || $resp->code eq '303') {
		print GREEN,"Logout OK\n",RESET;
	} else {
		print YELLOW,"Logout ERROR: ",RESET, $resp->status_line,"\n";
	}

	exit($fail);
}

