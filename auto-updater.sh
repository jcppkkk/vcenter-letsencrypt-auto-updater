#!/bin/bash

# vCenter/PSC SSL Certificate Updater.
# For more information see
#  https://wiki.9r.com.au/display/9R/LetsEncrypt+Certificates+for+vCenter+and+PSC

# Copyright (c) 2018 - Rob Thomas - xrobau@linux.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# You need to create a file called /root/.acme.sh/update.conf with the
# following lines in it:

CERTNAME='my.certificate.name'
ADMINACCOUNT='admin@vcenter.local'
ADMINPASS='admin'

# Replacing the values, obviously. 
if [ ! -e /root/.acme.sh/update.conf ]; then
	echo "No update.conf file configured, can not update. Read the update script for instructions!"
	exit 1
fi

. /root/.acme.sh/update.conf

# This is the sample file we compare against the latest file from acme.sh,
# and is present on both a PSC and a vCenter server.
CURRENTLIVE=/etc/vmware-rhttpproxy/ssl/rui.crt

# These environment variables are needed by vCenter
eval $(awk '{ print "export " $1 }' /etc/sysconfig/vmware-environment)

# Nothing should need to be touched below here
CERT=/root/.acme.sh/$CERTNAME/$CERTNAME.cer

if [ ! -e $CERT ]; then
	echo "Can't find cert $CERT - is update.conf correct?"
	exit 1
fi

# Compare the MD5sums of the running cert and the current LE cert
LIVEMD5=$(md5sum $CURRENTLIVE | cut -d\  -f1)
CURRENTMD5=$(md5sum $CERT | cut -d\  -f1)

if [ "$LIVEMD5" == "$CURRENTMD5" ]; then
	# Nothing to be done. Current certificate is correct
	exit 0
fi

# We need to update this machine with the new certificate.
KEY=/root/.acme.sh/$CERTNAME/$CERTNAME.key
CHAIN=/root/.acme.sh/$CERTNAME/fullchain.cer
CA=/root/.acme.sh/$CERTNAME/ca.cer

# Comodo AAA Certificate Services
ROOT=/root/.acme.sh/$CERTNAME/root.cer
cat > ${ROOT} <<EOF
-----BEGIN CERTIFICATE-----
MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQGEwJHQjEb
MBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRow
GAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmlj
YXRlIFNlcnZpY2VzMB4XDTA0MDEwMTAwMDAwMFoXDTI4MTIzMTIzNTk1OVowezEL
MAkGA1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
BwwHU2FsZm9yZDEaMBgGA1UECgwRQ29tb2RvIENBIExpbWl0ZWQxITAfBgNVBAMM
GEFBQSBDZXJ0aWZpY2F0ZSBTZXJ2aWNlczCCASIwDQYJKoZIhvcNAQEBBQADggEP
ADCCAQoCggEBAL5AnfRu4ep2hxxNRUSOvkbIgwadwSr+GB+O5AL686tdUIoWMQua
BtDFcCLNSS1UY8y2bmhGC1Pqy0wkwLxyTurxFa70VJoSCsN6sjNg4tqJVfMiWPPe
3M/vg4aijJRPn2jymJBGhCfHdr/jzDUsi14HZGWCwEiwqJH5YZ92IFCokcdmtet4
YgNW8IoaE+oxox6gmf049vYnMlhvB/VruPsUK6+3qszWY19zjNoFmag4qMsXeDZR
rOme9Hg6jc8P2ULimAyrL58OAd7vn5lJ8S3frHRNG5i1R8XlKdH5kBjHYpy+g8cm
ez6KJcfA3Z3mNWgQIJ2P2N7Sw4ScDV7oL8kCAwEAAaOBwDCBvTAdBgNVHQ4EFgQU
oBEKIz6W8Qfs4q8p74Klf9AwpLQwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wewYDVR0fBHQwcjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20v
QUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNqA0oDKGMGh0dHA6Ly9jcmwuY29t
b2RvLm5ldC9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDANBgkqhkiG9w0BAQUF
AAOCAQEACFb8AvCb6P+k+tZ7xkSAzk/ExfYAWMymtrwUSWgEdujm7l3sAg9g1o1Q
GE8mTgHj5rCl7r+8dFRBv/38ErjHT1r0iWAFf2C3BUrz9vHCv8S5dIa2LX1rzNLz
Rt0vxuBqw8M0Ayx9lt1awg6nCpnBBYurDC/zXDrPbDdVCYfeU0BsWO/8tqtlbgT2
G9w84FoVxp7Z8VlIMCFlA2zs6SFz7JsDoeA3raAVGI/6ugLOpyypEBMs1OUIJqsi
l2D4kF501KKaU73yqWjgom7C12yxow+ev+to51byrvLjKzg6CYG1a4XXvi3tPxq3
smPi9WIsgtRqAEFQ8TmDn5XpNpaYbg==
-----END CERTIFICATE-----
EOF

# Add Self-Signed to fullchain as required by certificate-manager
CHAIN_ROOT=/root/.acme.sh/$CERTNAME/fullchain-root.cer
cat $CHAIN $ROOT > $CHAIN_ROOT

CA_ROOT=/root/.acme.sh/$CERTNAME/ca-root.cer
cat $CA $ROOT > $CA_ROOT


# We delay briefly between account and password, as it's trying to open /dev/tty
# which has the potential to lose characters. To be on the safe side, we sleep
# between important bits. I feel that adding a 3 second delay to the upgrade that
# takes 10 minutes to run is not a big deal!

(
  printf '1\n%s\n' "$ADMINACCOUNT"
  sleep 1
  printf '%s\n' "$ADMINPASS"
  sleep 1
  printf '2\n'
  sleep 1
  printf '%s\n%s\n%s\ny\n\n' "$CHAIN_ROOT" "$KEY" "$CA_ROOT"
) | setsid /usr/lib/vmware-vmca/bin/certificate-manager

# 'setsid' detatches certman from /dev/tty, so it's forced to use stdin.
