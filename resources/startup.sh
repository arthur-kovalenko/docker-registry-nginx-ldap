# Copy and replace tokens for LDAP authentification
perl -p -i -e 's/###([^#]+)###/defined $ENV{$1} ? $ENV{$1} : $&/eg' < "/etc/nginx/temp/nginx.conf" 2> /dev/null 1> "/etc/nginx/nginx.conf"

# Get the private IP address for the container
PRIVATE_IP=$(ip addr | grep eth0 | awk '/inet / {sub(/\/.*/, "", $2); print $2}')
echo "Private IP address for nginx proxy container is $PRIVATE_IP"

WEBROOT_PATH="/usr/share/nginx/html"

function Get_Server_Address {
	# Get the public IP address for the container, if none is specified
	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
	fi

	if [ -z $ROOT_COMMON_NAME ]; then
		ROOT_COMMON_NAME="registry.${SERVER_IP}.nip.io"
	fi

	# Modify the openssl.cnf file, to add our SAN's
	sed -i "s/###IP###/$SERVER_IP/g" /etc/ssl/openssl.cnf
}

function Get_Lets_Encrypt_Certificates {
	git clone https://github.com/letsencrypt/letsencrypt
	cd letsencrypt

	if [ "$USE_LETS_ENCRYPT" == "test" ]; then
		USE_TEST="--test-cert"
	fi
	./letsencrypt-auto certonly ${USE_TEST} -a webroot --webroot-path=${WEBROOT_PATH} -d ${ROOT_COMMON_NAME} --register-unsafely-without-email --agree-tos

	rm /etc/nginx/conf.d/registry.conf
	cp /etc/nginx/temp/registry-lets-encrypt.conf /etc/nginx/conf.d/registry.conf
	
	mkdir -p /etc/nginx/ssl
	cp /etc/letsencrypt/live/${ROOT_COMMON_NAME}/fullchain.pem /etc/letsencrypt/live/${ROOT_COMMON_NAME}/privkey.pem /etc/nginx/ssl/
}

# Get server address
Get_Server_Address

# Generate certificates depending on which option was specified
if [ "$USE_LETS_ENCRYPT" == "true" ] || [ "$USE_LETS_ENCRYPT" == "test" ]; then
	Get_Lets_Encrypt_Certificates
fi

# Start nginx service
nginx -g 'daemon off;'