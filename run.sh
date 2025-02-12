#!/usr/bin/with-contenv bashio
set -e

SSH_DIR=~/.ssh
SSL_DIR=~/.ssl

ROUTER_USER="$(bashio::config 'sslFromAsusRouter.routerUser')"
ROUTER_IP="$(bashio::config 'sslFromAsusRouter.routerIp')"
ROUTER_PORT="$(bashio::config 'sslFromAsusRouter.routerSshPort')"
RSA_PRIVATE_KEY_PATH="$(bashio::config 'sslFromAsusRouter.rsaPrivateKeyPath')"
KEY_PATH_ON_ROUTER="$(bashio::config 'sslFromAsusRouter.keyFilePathOnRouter')"
CERT_PATH_ON_ROUTER="$(bashio::config 'sslFromAsusRouter.certFilePathOnRouter')"

echo "Getting Router Public RSA Key...."
ROUTER_RSA_KEY=$(ssh-keyscan -p ${ROUTER_PORT} -t rsa ${ROUTER_IP})

echo "Creating ${SSH_DIR}"
mkdir -p ${SSH_DIR}

echo "Creating ${SSL_DIR}"
mkdir -p ${SSL_DIR}

echo "Setting id_rsa file..."
cp /config/"${RSA_PRIVATE_KEY_PATH}" ${SSH_DIR}/id_rsa
chmod 600 ${SSH_DIR}/id_rsa

echo "Touching ${SSH_DIR}/known_hosts..."
touch ${SSH_DIR}/known_hosts

echo "Setting ${SSH_DIR}/known_hosts Permission..."
ls -lrt ${SSH_DIR}

echo "Saving know hosts..."
if grep -q "${ROUTER_RSA_KEY}" ${SSH_DIR}/known_hosts; then
	echo "Already known host..."
else
	echo "Not known Host, adding..."
	chmod 777 ${SSH_DIR}/known_hosts
	echo "$ROUTER_RSA_KEY" >> ${SSH_DIR}/known_hosts
fi

chmod 644 ${SSH_DIR}/known_hosts;
cat ${SSH_DIR}/known_hosts

echo "piping ssh certificates to file ..."
ssh ${ROUTER_USER}@${ROUTER_IP} -p ${ROUTER_PORT} "cat ${KEY_PATH_ON_ROUTER}" > /ssl/key.pem
ssh ${ROUTER_USER}@${ROUTER_IP} -p ${ROUTER_PORT} "cat ${CERT_PATH_ON_ROUTER}" > /ssl/cert.pem

echo "creating cert.p12 to send to android phone ..."
openssl pkcs12 -export -keypbe NONE -certpbe NONE -nomaciter -passout pass: -in /ssl/cert.pem -inkey /ssl/key.pem -out ${SSL_DIR}/cert.p12