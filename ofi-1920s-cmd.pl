#!/usr/bin/perl
## Author: Dariusz Zielinski-Kolasinski
## Licence: GPL
## Version: 1.0 (2020-10-04)
##
## This is HPE OfficeConnect Switch 1920S 8G JL380A cli command script
## Tested with PD.02.12 firmware
##


use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Term::ANSIColor qw(:constants);

### INPUT
if ($#ARGV < 3) {
	print "Usage: $0 <ip/hostname> <user> <pass> <command> [command extra options]\n";
	print "  commands:\n";
	print "  - wr-mem [options: none] - write memory (save configuration)\n";
	print "  - reset [options: none] - reboot switch\n";
	print "  - set-log-host [options: <syslog IP>] - set remote logging host with all default logging settings\n";
	exit(1);
}

### VALIDATE INPUT
my $username = $ARGV[1];
my $password = $ARGV[2];
my $host = $ARGV[0];
my $command = $ARGV[3];
my $extra1;
my $extra2;
my $extra3;

unless ($host =~ /^[0-9a-zA-Z\.\-]+$/) {
	print RED,"IP/Hostname - input does not match pattern!\n",RESET;
	exit(1);
}

### COMMAND:
if ($command eq 'wr-mem' || $command eq 'reset') {
	# no valdiation needed
} elsif ($command eq 'set-log-host') {
	if ($#ARGV != 4 || !($ARGV[4] =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)) {
		print RED,"ERROR: parameters for: $command\n";
		exit(1);
	}
	$extra1 = $ARGV[4];
} else {
	print RED,"ERROR: unknown command: $command\n";
	exit(1);
}


### INIT
my $cookie_jar = HTTP::Cookies->new();
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

### HANDLE COMMAND
if ($command eq 'wr-mem') {
	$req = POST 'http://'.$host.'/htdocs/lua/ajax/save_cfg.lua?save=1', [];

	$resp = $ua->request( $req );
	my $params = '';
	if ($resp->is_success) {
		if ( $resp->content =~ /Operation succeeded/) {
			print GREEN,"REQ OK, response: ",RESET,"Operation succeeded\n";
		} else {
			print RED,"UNKNOWN RESPONSE: ",RESET,$resp->content,"\n";
		}
	} else {
		print RED,"REQ COMMAND ERROR: ",RESET, $resp->status_line,"\n";
	}
} elsif ($command eq 'reset') {
	$req = POST 'http://'.$host.'/htdocs/lua/ajax/sys_reset_ajax.lua?reset=1', [];

	$ua->timeout(2);
	$ua->request( $req );
	print GREEN, "REQ SENT, NO RESPONSE EXPECTED",RESET,"\n";
	exit(0);
} elsif ($command eq 'set-log-host') {
	$req = POST 'http://'.$host.'/htdocs/pages/base/log_cfg.lsp', [
		'admin_status_buff_sel[]' => 'enabled',
		'severity_filter_buffered_sel[]' => 'info',
		'sys_severity_filter_sel[]' => 'info',
		'admin_status_syslog_sel[]' => 'enabled',
		'ip_address' => $extra1,
		'port' => '514',
		'b_form1_clicked' => 'b_form1_submit',
		'b_form1_submit' => 'Apply'
	];

	$resp = $ua->request( $req );
	my $params = '';
	if ($resp->is_success) {
		if ( $resp->content =~ /\>Log Configuration\</) {
			print GREEN,"REQ PROBABLY OK, response: ",RESET,"Log settings page\n";
		} else {
			print RED,"UNKNOWN RESPONSE: ",RESET,$resp->content,"\n";
		}
	} else {
		print RED,"REQ COMMAND ERROR: ",RESET, $resp->status_line,"\n";
	}
}

### LOGOUT
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

