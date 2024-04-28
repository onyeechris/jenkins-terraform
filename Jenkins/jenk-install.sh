#!/bin/bash

sudo apt update -y
#Step 1 — Installing Jenkins

#First, add the repository key to your system:
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg

#Debian/Ubuntu weekly release
sudo curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y

#install Jenkins and its dependencies:
sudo apt install default-jre -y
sudo apt install jenkins -y

#Step 2 — Starting Jenkins
sudo systemctl enable jenkins.service
sudo systemctl start jenkins.service


#install git
sudo apt install git -y

#install terraform
sudo apt-get install unzip
sudo wget https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip
sudo unzip terraform_1.0.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/

#install kubectl

sudo curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/arm64/kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl