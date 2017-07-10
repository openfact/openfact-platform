#!/usr/bin/env bash

LATEST="latest"
OPENFACT_VERSION=${1:-$LATEST}

if [ "$OPENFACT_VERSION" == "$LATEST" ] || [ "$OPENFACT_VERSION" == "" ] ; then
  OPENFACT_VERSION=$(curl -sL http://central.maven.org/maven2/io/openfact/platform/packages/openfact-system/maven-metadata.xml | grep '<latest' | cut -f2 -d">"|cut -f1 -d"<")
fi

TEMPLATE="packages/openfact-system/target/classes/META-INF/fabric8/openshift.yml"

if [ "$OPENFACT_VERSION" == "local" ] ; then
  echo "Installing using a local build"
else
  echo "Installing openfact version: ${OPENFACT_VERSION}"
  TEMPLATE="http://central.maven.org/maven2/io/openfact/platform/packages/openfact-system/${OPENFACT_VERSION}/openfact-system-${OPENFACT_VERSION}-openshift.yml"
fi
echo "Using the openfact template: ${TEMPLATE}"

oc login -u developer -p developer

oc new-project openfact


APISERVER=$(oc version | grep Server | sed -e 's/.*http:\/\///g' -e 's/.*https:\/\///g')
NODE_IP=$(echo "${APISERVER}" | sed -e 's/:.*//g')
#EXPOSER="NodePort"
EXPOSER="Route"

echo "Connecting to the API Server at: https://${APISERVER}"
echo "Using Node IP ${NODE_IP} and Exposer strategy: ${EXPOSER}"
echo "Using github client ID: ${GOOGLE_OAUTH_CLIENT_ID} and secret: ${GOOGLE_OAUTH_CLIENT_SECRET}"


OPENFACT_ID="${GOOGLE_OAUTH_CLIENT_ID}"
OPENFACT_SECRET="${GOOGLE_OAUTH_CLIENT_SECRET}"

echo "Applying the OPENFACT template ${TEMPLATE}"
oc process -f ${TEMPLATE} -p APISERVER_HOSTPORT=${APISERVER} -p NODE_IP=${NODE_IP} -p EXPOSER=${EXPOSER} -p GOOGLE_OAUTH_CLIENT_SECRET=${OPENFACT_SECRET} -p GOOGLE_OAUTH_CLIENT_ID=${OPENFACT_ID} | oc apply -f -

echo "Please wait while the pods all startup!"
echo
echo "To watch this happening you can type:"
echo "  oc get pod -l provider=openfact -w"
echo
echo "Or you can watch in the OpenShift console via:"
echo "  minishift console"
echo
echo "Then you should be able the open the openfact console here:"
echo "  http://`oc get route openfact --template={{.spec.host}}`/"
