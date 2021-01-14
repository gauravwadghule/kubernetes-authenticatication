#!/bin/bash

#Required
domain=developer-test
commonname=nilesh

#Change to your company details
country=IN
state=Maharashtra
locality=Pune
organization=Your Organization
organizationalunit=IT
email=administrator@mycompany.net


echo "Generating key request for $domain"

#Generate a key
openssl genrsa -out $domain.key 4096

#Create the request
echo "Creating CSR"
openssl req -new -key $domain.key -out $domain.csr \
    -subj "//C=$country\ST=$state\L=$locality\O=$organization\OU=$organizationalunit\CN=$commonname\emailAddress=$email"

echo "---------------------------"
echo "-----Below is your CSR-----"
echo "---------------------------"
echo
cat $domain.csr

echo
echo "---------------------------"
echo "-----Below is your Key-----"
echo "---------------------------"
echo
cat $domain.key

csr_base64=$(cat $domain.csr | base64 | tr -d "\n")

cat << EOF > CertificateSigningRequest.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${commonname}
spec:
  groups:
  - system:authenticated
  request: ${csr_base64}
  usages:
  - client auth
EOF

cat CertificateSigningRequest.yaml

#Create the CertificateSigningRequest
echo "Creating CertificateSigningRequest in kubernetes"
export csr_base64=$csr_base64
export commonname=$commonname
cat CertificateSigningRequest.yaml | envsubst | kubectl apply -f -

#Approving CertificateSigningRequest
echo "Approving CertificateSigningRequest in kubernetes"
kubectl get csr
kubectl certificate approve $commonname

#creating Client Certificate
echo "creating Client Certificate"
kubectl get csr $commonname -o jsonpath='{.status.certificate}' | base64 --decode > ${commonname}-client-certificate.crt

#creating clusterrole
# echo "Creating Cluster Role"
# cat << EOF > clusterRole.yaml
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRole
# metadata:
#   namespace: default
#   name: developer
# rules:
# - apiGroups: [""]
#   resources: ["pods", "pods/log"]
#   verbs: ["get", "list"]
# EOF

# kubectl apply -f clusterRole.yaml

kubectl create clusterrole developer --verb=get --resource=pods,pod/logs

kubectl create clusterrolebinding developer-${commonname} --clusterrole=developer --user=${commonname}

