# docker-registry

Docker registry with Nginx authentification with LDAP and Lets Encrypt SSL certificates. This registry is intended to be used on ADOP stack. For more information regarding ADOP, please see https://github.com/Accenture/adop-docker-compose

Do NOT use self-signed SSL certificates with docker registry. It is possible to use them, but you will need to either copy them to any machine that will authenticate with your private registry, or provide an --insecure-registry flag to docker deamon. If you are running a docker registry on localhost, and and planning to push and pull images only from the same local machine, you do NOT need to use any certificates, and plain, "Vanilla" registry will work fine as well.

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