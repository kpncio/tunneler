#!/bin/bash

#####
#  Installation:
#
#  ovpn.sh <protocol[udp]> <port[1194]> <primary dns[1.1.1.1]> <secondary dns[1.0.0.1]>
#
#  (Default and fast - up to 5Gbi/s on AWS t3, t3a, t4g):   ovpn.sh udp 1194 1.1.1.1 1.0.0.1
#  (This will create the same exact setup as thee above):   ovpn.sh
#  (Useful for limited networks, but much slower on tcp):   ovpn.sh tcp 80 8.8.8.8 8.8.4.4
#
#  Then go to "http://<ipaddress>/" (or "http://<ipaddress>:8080/" if vpn port is set to 80) to download OpenVPN config
#  You can use this configuration file in an OpenVPN client application
#####

#####
#  Information:
#
#  This script was made specifically as a quick and dirty VPN installer for AWS Instance Templates;
#  however, it should work fine at other cloud vendors...
#
#  KPNC Technology (2023)
#  OpenVPN CE with Easy-RSA and Ubuntu
#  Inspired by Nyr's Road Warrior OpenVPN Installer (git.io/vpn)
#####

clear

echo "Welcome to KPNC's one-click VPN..."

# Get Commandline Arguements
protocol=$1
[[ -z "$protocol" ]] && protocol="udp"
echo "Protocol is $protocol"

port=$2
[[ -z "$port" ]] && port="1194"
echo "Port is $port"

dnsone=$3
[[ -z "$dnsone" ]] && dnsone="1.1.1.1"
echo "Primary DNS is $dnsone"

dnstwo=$4
[[ -z "$dnstwo" ]] && dnstwo="1.0.0.1"
echo "Secondary DNS is $dnstwo"

sleep 5
clear -x

# Update System and Install Dependencies
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

apt-get install openvpn easy-rsa openssl ca-certificates iptables -y

apt-get install apache2 php7.4 libapache2-mod-php7.4 -y
a2enmod php7.4
envvars=`cat /etc/apache2/envvars`
rm -rf /etc/apache2/*
rm -rf /var/www/html/*
systemctl restart apache2

apt-get autoremove -y
apt-get clean
apt-get autoclean

sleep 5
clear -x

mkdir -p /etc/openvpn/server/
cd /etc/openvpn/server/

# Configure Apache
httpd="80"

if [[ "$port" = "80" ]]; then
    httpd="8080"
fi

echo "$envvars" > /etc/apache2/envvars

echo "ServerName localhost
ServerAdmin root@localhost
ServerRoot /var/www/
User \${APACHE_RUN_USER}
Group \${APACHE_RUN_GROUP}
PidFile \${APACHE_PID_FILE}
ServerTokens Prod
UseCanonicalName On
TraceEnable Off
Timeout 10
MaxRequestWorkers 100
Listen $httpd
<FilesMatch \".+\.ph(ar|p|tml)$\">
    SetHandler application/x-httpd-php
</FilesMatch>
<FilesMatch \".+\.phps$\">
    SetHandler application/x-httpd-php-source
    Require all denied
</FilesMatch>
<FilesMatch \"^\.ph(ar|p|ps|tml)$\">
    Require all denied
</FilesMatch>
<IfModule mod_userdir.c>
    <Directory /home/*/public_html>
        php_admin_flag engine Off
    </Directory>
</IfModule>
LoadModule mpm_prefork_module /usr/lib/apache2/modules/mod_mpm_prefork.so
# LoadModule mpm_event_module /usr/lib/apache2/modules/mod_mpm_event.so
LoadModule authn_core_module /usr/lib/apache2/modules/mod_authn_core.so
LoadModule authz_core_module /usr/lib/apache2/modules/mod_authz_core.so
LoadModule php_module /usr/lib/apache2/modules/libphp8.1.so
LoadModule dir_module /usr/lib/apache2/modules/mod_dir.so
<IfModule mod_dir.c>
    DirectoryIndex index.php
</IfModule>
ErrorLogFormat \"[%{cu}t] [%-m:%-l] %-a %-L %M\"
LogFormat \"%h %l %u [%{%Y-%m-%d %H:%M:%S}t.%{usec_frac}t] \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\"\" combined
LogLevel warn
ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined
DocumentRoot /var/www/html/
<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>
<Directory /usr/share>
	AllowOverride None
	Require all granted
</Directory>
<Directory /var/www/>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
AccessFileName .htaccess
<FilesMatch \"^\\.ht\">
	Require all denied
</FilesMatch>
<VirtualHost *:$httpd>
	<Directory /var/www/html/>
		Require all granted
		Options None
	</Directory>
</VirtualHost>" > /etc/apache2/apache2.conf

systemctl restart apache2

# Create RSA Certificates
/usr/share/easy-rsa/easyrsa --batch init-pki
/usr/share/easy-rsa/easyrsa --batch build-ca nopass
/usr/share/easy-rsa/easyrsa --batch --days=3650 build-server-full server nopass
/usr/share/easy-rsa/easyrsa --batch --days=3650 build-client-full client nopass
/usr/share/easy-rsa/easyrsa --batch --days=3650 gen-crl

cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/crl.pem ./

chown nobody:nogroup crl.pem

chmod o+x ./

openvpn --genkey --secret tc.key

echo "-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----" > dh.pem

sleep 5
clear -x

# Create OpenVPN Server
ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')

get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")

[[ -z "$public_ip" ]] && public_ip="$get_public_ip"

echo "local $ip
port $port
proto $protocol
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server 10.8.0.0 255.255.255.0
push \"redirect-gateway def1 bypass-dhcp\"
ifconfig-pool-persist ipp.txt
push \"dhcp-option DNS $dnsone\"
push \"dhcp-option DNS $dnstwo\"
push \"block-outside-dns\"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
verb 3
crl-verify crl.pem" > server.conf

if [[ "$protocol" = "udp" ]]; then
    echo "explicit-exit-notify" >> server.conf
fi

echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-openvpn-forward.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

iptables_path=$(command -v iptables)

echo "[Unit]
Before=network.target
[Service]
Type=oneshot
ExecStart=$iptables_path -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $ip
ExecStart=$iptables_path -I INPUT -p $protocol --dport $port -j ACCEPT
ExecStart=$iptables_path -I FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStart=$iptables_path -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$iptables_path -t nat -D POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $ip
ExecStop=$iptables_path -D INPUT -p $protocol --dport $port -j ACCEPT
ExecStop=$iptables_path -D FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStop=$iptables_path -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" > /etc/systemd/system/openvpn-iptables.service

echo "RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/openvpn-iptables.service

systemctl enable --now openvpn-iptables.service

[[ -n "$public_ip" ]] && ip="$public_ip"

echo "client
dev tun
proto $protocol
remote $ip $port
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
verb 3" > client-common.txt

systemctl enable --now openvpn-server@server.service

{
    cat client-common.txt
    echo "<ca>"
    cat pki/ca.crt
    echo "</ca>"
    echo "<cert>"
    sed -ne '/BEGIN CERTIFICATE/,$ p' pki/issued/client.crt
    echo "</cert>"
    echo "<key>"
    cat pki/private/client.key
    echo "</key>"
    echo "<tls-crypt>"
    sed -ne '/BEGIN OpenVPN Static key/,$ p' tc.key
    echo "</tls-crypt>"
} > /var/www/html/client.ovpn

sleep 5
clear -x

echo "<!doctypehtml><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta content=\"IE=edge\"http-equiv=\"X-UA-Compatible\"><meta content=\"width=device-width,initial-scale=1\"name=\"viewport\"><title>OpenVPN</title><style>body{margin:0;padding:0;width:100vw;height:100vh;overflow:hidden;position:relative;text-align:center;scroll-behavior:smooth;color:#fff;font-family:Inter,Roboto,Arial,sans-serif;background:linear-gradient(165deg,#14fcc3 0,#8814fc 100%)}table{top:50%;left:50%;padding:40px;position:absolute;border-radius:10px;letter-spacing:normal;transform:translate(-50%,-50%);background-color:#1e1e1e}h1{font-size:18px;padding:10px 40px;border-radius:10px;margin-bottom:20px;color:#ffc107;border:2px #ffc107 solid}input{width:100%;font-size:24px;line-height:2rem;padding:10px 40px;border-radius:10px;color:#fff;background-color:transparent;border:2px #fff solid}input:hover{background-color:rgba(255,255,255,.1)}</style></head><body><table><tr><td><?php \$file='client.ovpn';if(array_key_exists('download',\$_GET)){download(\$file);}else if(array_key_exists('delete',\$_GET)){delete(\$file);}function download(\$file){if(file_exists(\$file)){header('Location: download.php?path='.\$file);die();}else{notify('Could not find configuration file...');}}function delete(\$file){if(!unlink(\$file)){notify('Could not delete configuration file...');}else{notify('Configuration has been deleted...');}}function notify(\$message){echo('<h1>'.\$message.'</h1>');} ?></td></tr><tr><td><form><input name=\"download\"type=\"submit\"value=\"Download\"style=\"margin-bottom:20px\"></form></td></tr><tr><td><form><input name=\"delete\"type=\"submit\"value=\"Delete\"></form></td></tr></table></body></html>" > /var/www/html/index.php

echo "<?php \$file='client.ovpn';if(file_exists(\$file)){header('Content-Description: File Transfer');header('Content-Type: application/octet-stream');header(\"Cache-Control: no-cache, must-revalidate\");header(\"Expires: 0\");header('Content-Disposition: attachment; filename=\"client.ovpn\"');header('Content-Length: '.filesize(\$file));header('Pragma: public');flush();readfile(\$file);die();}else{echo \"Could not find configuration...\";} ?>" > /var/www/html/download.php

echo "OpenVPN server has been installed on this instance..."
