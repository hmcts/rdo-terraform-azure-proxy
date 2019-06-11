#!/bin/bash

mkdir -p /etc/rdo-docker-proxy/squid
mkdir -p /var/log/rdo-docker-proxy/squid
hostname > /etc/ansible/hosts

curl -sL https://aka.ms/InstallAzureCLIDeb | bash
az login --service-principal -u $1 -p $2 --tenant $3

az vm assign -g dmz -n proxy-sbox --identities '/subscriptions/bf308a5c-0624-4334-8ff8-8dca9fd43783/resourcegroups/dmz/providers/Microsoft.ManagedIdentity/userAssignedIdentities/isher-has-mi'

token=`curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | cut -d, -f1 | cut -d: -f2 | sed 's/"//g'`
gh_user=`curl -s https://infra-ops-kv.vault.azure.net/secrets/github-devops-access-credentials?api-version=2016-10-01 -H "Authorization: Bearer $token" | cut -d, -f1 | cut -d: -f2 | sed 's/\"//g' | cut -d/ -f1`
gh_token=`curl -s https://infra-ops-kv.vault.azure.net/secrets/github-devops-personal-access-token?api-version=2016-10-01 -H "Authorization: Bearer $token" | cut -d, -f1 | cut -d: -f2 | sed 's/\"//g'`

git clone https://${gh_user}:${gh_token}@github.com/hmcts/rdo-ansible-squid.git
ansible-playbook ~/rdo-ansible-squid/squid.yml

#git clone https://${gh_user}:${gh_token}@github.com/hmcts/rdo-docker-proxy.git
#ansible-playbook ~/rdo-docker-proxy/proxy.yml