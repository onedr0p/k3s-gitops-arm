# HAProxy and Cloudflare

As an example I am using the domains `awesomewebsite.net` and `radwebsite.io` for the domains I want to use.

## Install HAProxy on a separate device

> **Note**: These instructions are for Debian based distros

```bash
sudo add-apt-repository ppa:vbernat/haproxy-2.0
sudo apt-get update
sudo apt-get install haproxy
```

## Obtain Origin CA certificate from Cloudflare

> **Note**: You need to create an Origin CA cert for each domain

See [this article](https://support.cloudflare.com/hc/en-us/articles/115000479507-Managing-Cloudflare-Origin-CA-certificates) for how to obtain an Origin CA cert from Cloudflare.

Save the `pem` and `key` files in the `/etc/haproxy` directory as `<domain.tld>.pem` and `<domain.tld>.key`

## Merge the .crt and .key file into one file per domain

> **Note**: You need to do this for each domain

```bash
sudo cat awesomewebsite.net.pem awesomewebsite.net.key > /etc/haproxy/awesomewebsite.net-haproxy.pem
sudo cat radwebsite.pem radwebsite.key > /etc/haproxy/radwebsite-haproxy.pem
```

## Configure HAProxy

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

```apacheconf
global
  log /dev/log local0
  log /dev/log local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s
  user haproxy
  group haproxy
  daemon
  maxconn 4096

defaults
  log global
  option redispatch
  timeout connect 5000
  timeout client 50000
  timeout server 50000
  errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http

frontend http-in
  bind *:80
  #
  # @CHANGEME - Update crt paths to your merged pem and key domain files
  #
  bind *:443 ssl crt /etc/haproxy/awesomewebsite.net-haproxy.pem crt /etc/haproxy/radwebsite.io-haproxy.pem
  mode http
  option forwardfor

  # Define known networks for later use
  acl local src 127.0.0.0/8 192.168.1.0/24 192.168.42.0/24
  acl cloudflare src 173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/12 172.64.0.0/13 131.0.72.0/22 2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32 2405:8100::/32 2a06:98c0::/29 2c0f:f248::/32

  # Table for connection tracking
  stick-table type ip size 100k expire 30s store conn_cur

  # Allow known CloudFlare IPs to bypass the rate-limiting
  tcp-request connection accept if cloudflare

  # Reject connection if client has more than 10 open
  tcp-request connection reject if { src_conn_cur ge 10 }
  tcp-request connection track-sc1 src

  # Max inspection delay for SNI routing
  tcp-request inspect-delay 2s

  # Accept only SSL/TLS traffic
  tcp-request content accept if { req_ssl_hello_type 1 }

  # Domains to route
  #
  # @CHANGEME - Update to your domain names
  #
  acl awesomewebsite hdr_end(host) -i awesomewebsite.net
  acl radwebsite hdr_end(host) -i radwebsite.io

  # Backends for each domain to use
  #
  # @CHANGEME - Customize as needed
  #
  use_backend server1 if awesomewebsite
  use_backend server2 if radwebsite

#
# @CHANGEME - Customize as needed, update IP:PORT to point to server1
#
backend server1
  mode http
  balance roundrobin
  server main 192.168.1.160:80
  http-request add-header X-Forwarded-Proto https

#
# @CHANGEME - Customize as needed, update IP:PORT to point to server2
#
backend server2
  mode http
  balance roundrobin
  server main 192.168.42.100:80
  http-request add-header X-Forwarded-Proto https
```

## Restart HAProxy

```bash
sudo systemctl restart haproxy
```

## Port forward to HAProxy

Last thing you need to do is update your router to point to this HAProxy server.
