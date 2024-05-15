A simple URL shortener written in Nim
###

1. Build, place binary on server.

2. Create a password and place it in NIMSHORT_TOKEN env var, run nimshort to let it hash it for you and print a hash.

```
$ export NIMSHORT_TOKEN=mysecuritytoken
$ nimshort
abc123
```

3. Start with with systemd.

```s
# /etc/systemd/system/nimshort.target
[Unit]
Description=nimshort
After=network.target httpd.service
Wants=network-online.target

[Service]
DynamicUser=True
ExecStart=nimshort
Restart=always
NoNewPrivileges=yes
PrivateDevices=yes
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
Environment=NIMSHORT_HASH=abc123 NIMSHORT_PORT=7071
0567ac01f91
StateDirectory=nimshort
WorkingDirectory=%S/nimshort

[Install]
WantedBy=multi-user.target
```

```
$ systemctl start nimshort
$ systemctl enable nimshort
```

4. Proxy with nginx


```
# /etc/nginx/sites-available/short.url
server {
  server_name capo.casa;
  listen 80;
  listen [::]:80;
  return 301 https://$host$request_uri;
}
server {
  server_name short.url;
  listen 443 ssl;
  listen [::]:443 ssl;
  ssl_certificate /etc/letsencrypt/live/short.url/fullchain
.pem;
  ssl_certificate_key /etc/letsencrypt/live/short.url/privk
ey.pem;
  include /etc/letsencrypt/options-ssl-nginx.conf;

  location / {
    root /var/www/short.url;
    try_files $uri $uri/ @nimshort;
  }
  location @nimshort {
    proxy_pass http://127.0.0.1:7071;
    proxy_buffering off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
  }
  access_log /var/log/nginx/short.url.access.log;
  error_log /var/log/nginx/short.url.error.log;
}
```

```
$ certbot -d short.url --nginx certonly
$ ln -s /etc/nginx/sites-available/short.url /etc/nginx/sites-enabled
$ nginx -t
$ systemctl reload nginx
```

5. Shorten URLs

```
curl -H 'Auth: Bearer mysecuritytoken' -XPUT -d "https://reall.long.url" https://capo.casa/myshort
```

Note you provide your own myshort url component.


