# Copy and replace tokens for LDAP authentification
perl -p -i -e 's/###([^#]+)###/defined $ENV{$1} ? $ENV{$1} : $&/eg' < "/etc/nginx/temp/nginx.conf" 2> /dev/null 1> "/etc/nginx/nginx.conf"

# Get the private IP address for the container
PRIVATE_IP=$(ip addr | grep eth0 | awk '/inet / {sub(/\/.*/, "", $2); print $2}')
echo "Private IP address for nginx proxy container is $PRIVATE_IP"

# Function to generate new self-signed certificates for proxy container
function Generate_Certificates {
	# Get the public IP address for the container, if none is specified
	SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
	if [ -z $ROOT_COMMON_NAME ]; then
		ROOT_COMMON_NAME="registry.${SERVER_IP}.xip.io"
	fi

	# Modify the openssl.cnf file, to add our SAN's
	sed -i "s/###IP###/$SERVER_IP/g" /etc/ssl/openssl.cnf

	mkdir -p /tmp/certs && cd /tmp/certs

	# Generate a new root key
	openssl genrsa -out devdockerCA.key 2048
	# Generate a new root certificate
	openssl req -x509 -new -passin pass:${PASS_ROOT} -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${ROOT_COMMON_NAME}/emailAddress=${EMAIL}" -nodes -key devdockerCA.key -days 10000 -out devdockerCA.crt
	# Generate a key for server
	openssl genrsa -out domain.key 2048
	# Make a certificate signing request
	openssl req -new -passin pass:${PASS_ROOT} -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${ROOT_COMMON_NAME}/emailAddress=${EMAIL}" -key domain.key -out dev-docker-registry.csr
	# Sign the certificate request
	openssl x509 -req -in dev-docker-registry.csr -CA devdockerCA.crt -CAkey devdockerCA.key -CAcreateserial -out domain.crt -days 10000

	# copy generated certificates to nginx configuration
	mkdir -p /etc/nginx/ssl
	cp domain.key /etc/nginx/ssl/domain.key
	cp domain.crt /etc/nginx/ssl/domain.crt
	echo "INF: Certificates successfully generated"
}

Generate_Certificates
# Start nginx service
nginx -g 'daemon off;'