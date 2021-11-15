#! /bin/bash

name="mvmltm"
storage="https://${name}.blob.core.windows.net/f5-bigip/bigip.conf"

tokenUrl="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F"
tokenHdr="-HMetadata:true"

echo "curl -0s $tokenHdr '$tokenUrl'"
token=$(curl -0s $tokenHdr $tokenUrl | jq -r .access_token)
storageHdrs="-H \"x-ms-version: 2017-11-09\" -H \"Authorization: Bearer $token\""
stHdr01="x-ms-version:2017-11-09"
stHdr02="Authorization: Bearer $token"

#echo "token:    $token"
#echo "stHdr01:  $stHdr01"
#echo "stHdr02:  $stHdr02"



echo curl -0s -H \"$stHdr01\" -H \"$stHdr02\" $storage 
curl -0s -H "$stHdr01" -H "$stHdr02" $storage 
