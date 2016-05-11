# docker-registry

Docker registry with Nginx authentification with LDAP and self-signed SSL certificates. This registry is intended to be used on ADOP stack. For more information regarding ADOP, please see https://github.com/Accenture/adop-docker-compose

## Usage instructions

Create a custom docker network, if you do not have one already present:

```
export CUSTOM_NETWORK_NAME=local_network 
docker network create $CUSTOM_NETWORK_NAME
```

Build the provided Dockerfile for the Nginx proxy:

```docker-compose build```

Export LDAP credentials:

```
export LDAP_FULL_DOMAIN=example.com
export LDAP_PWD=pass
```

Run the docker registry and proxy using docker-compose:

```docker-compose up -d```

You will be able to access your docker registry via https://localhost:5043/

## Testing

To test if the registry is accessible, you can run a curl request:

```
curl -k https://user:password@localhost:5043/v2/
```

Output should be `{}`