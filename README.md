# hp1920s-backup-script
HPE OfficeConnect Switch 1920S 8G JL380A startup-configuration download script

### Requirements

- Perl
- LWP::Simple (Debian/Ubuntu: libwww-perl package)

### Usage

As simple as:

```
./ofi-1920s-get-backup.pl <ip/hostname> <user> <pass> <output filename>
```

### Examples

```
./ofi-1920s-get-backup.pl 10.10.10.10 admin some.password /tmp/download1
LOGIN OK
REQ FILE OK, params: ?name=startup-config&file=/mnt/download/startup-config&token=1591177096000
DOWNLOAD OK
CLEANUP OK
Logout OK 
```

```
./ofi-1920s-get-backup.pl 10.10.10.10 admin some.password /tmp/download1
LOGIN OK
REQ FILE OK, BUT ERROR FOUND {"successful": false, "errorMsgs": "Error: A file transfer is currently in progress.  No other transfers may be initiated while the other transfer is underway.\r\n\r\n" }
Logout OK
```
