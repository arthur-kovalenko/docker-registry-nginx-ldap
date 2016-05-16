FROM ubuntu:14.04

MAINTAINER Arthur Kovalenko <arthur.kovalenko>

# Install the required tools
RUN apt-get update && \
	apt-get install -y git build-essential libldap2-dev libssl-dev libpcre3-dev wget openssl dnsutils && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Download and compile nginx from source with LDAP support
RUN mkdir -p /tmp/nginx && \
	cd /tmp/nginx && \
	wget http://nginx.org/download/nginx-1.7.7.tar.gz && \
	git clone https://github.com/kvspb/nginx-auth-ldap.git && \
	tar -xvzf nginx-1.7.7.tar.gz && \
	cd nginx-1.7.7 && \
	chmod +x configure && \
	./configure --user=nginx \
		--group=nginx \
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--with-http_gzip_static_module \
		--with-http_stub_status_module \
		--with-http_ssl_module \
		--with-pcre \
		--with-file-aio \
		--with-http_realip_module \
		--with-http_ssl_module \
		--add-module=/tmp/nginx/nginx-auth-ldap/ \
		--with-ipv6 \
		--with-debug && \
	make && make install && \
	cd .. && \
	rm -rf /tmp/nginx

# RUN wget https://raw.githubusercontent.com/calvinbui/nginx-init-ubuntu/master/nginx -O /etc/init.d/nginx && \
#	chmod +x /etc/init.d/nginx && \
#	update-rc.d -f nginx defaults

# Set environment variables
ENV COUNTRY GB
ENV STATE England
ENV LOCALITY London
ENV ORGANIZATION ADOP
ENV UNIT ADOP
ENV EMAIL example@example.com

# Copy configuration files
COPY ./resources/nginx/conf.d/registry.conf /etc/nginx/conf.d/registry.conf
COPY ./resources/nginx/nginx.conf /etc/nginx/temp/nginx.conf
COPY ./resources/nginx/registry-lets-encrypt.conf /etc/nginx/temp/registry-lets-encrypt.conf
COPY ./resources/openssl.cnf /etc/ssl/openssl.cnf
# COPY ./resources/nginx/registry.password /etc/nginx/conf.d/registry.password
COPY ./resources/startup.sh /bin/startup.sh

RUN chmod +x /bin/startup.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/bin/startup.sh"]