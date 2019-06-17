curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sleep 30
echo sudo az login --service-principal --username $(CLIENT_ID) --password $(CLIENT_SECRET) --tenant $(TENANT_ID)
hostname > ~/ansible/hosts
cd ~/ansible
sudo ansible-playbook ~/ansible/proxy.yml -i ~/ansible/hosts
  