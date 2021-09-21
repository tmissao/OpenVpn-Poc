
\\wsl$\Ubuntu-18.04\root\poc\openvpn\src\terraform
C:\Program Files\OpenVPN\config

---

ssh adminuser@52.168.52.159 'bash client-configs/make_config.sh tiago'
sftp adminuser@52.168.52.159:client-configs/files/tiago.ovpn ./

---

nslookup missaoaz303test.blob.core.windows.net

az login -i
echo "hello from vm" > vm.txt
az storage blob upload --account-name missaoaz303test -f ./vm.txt -c test -n vm.txt

---

https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04
https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-20-04