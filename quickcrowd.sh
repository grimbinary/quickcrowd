#!/bin/bash
OS=$(uname -s)

if [ "$OS" == "Linux" ]; then
     DISTRO=$(source /etc/os-release; echo $NAME)
fi
if [ "$OS" == "Linux" ]; then
    if [[ "$DISTRO" == *"Debian"* ]]; then
        echo -e "\e[1;33mInstalling Docker on Debian\e[0m"
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
          $(lsb_release -cs) stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [[ "$DISTRO" == *"Ubuntu"* ]]; then
        echo -e "\e[1;33mInstalling Docker on Ubuntu\e[0m"
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [[ "$DISTRO" == *"CentOS"* ]]; then
        echo -e "\e[1;33mInstalling Docker on CentOS\e[0m"
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
fi
elif [ "$OS" == "Darwin" ]; then
  echo -e "\e[1;33mInstalling Docker on macOS\e[0m"
  read -p "Is your macOS system Apple Silicon (y/n)? " APPLE_SILICON
  if [ "$APPLE_SILICON" == "y" ]; then
    softwareupdate --install-rosetta
    sudo hdiutil attach Docker.dmg
    sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
    sudo hdiutil detach /Volumes/Docker
  else
    sudo hdiutil attach Docker.dmg
    sudo /Volumes/Docker/Docker.app/Contents/MacOS/install
    sudo hdiutil detach /Volumes/Docker
  fi
else
  echo "Unsupported operating system"
fi
 sudo docker run hello-world
if [ "$OS" == "Linux" ]; then
    DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

    if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"Debian"* ]]; then
        echo -e "\e[1;33mInstalling CrowdSec agent on Debian/Ubuntu\e[0m"
        curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
        sudo apt-get install -y crowdsec
    elif [[ "$DISTRO" == *"CentOS"* ]] || [[ "$DISTRO" == *"RHEL"* ]] || [[ "$DISTRO" == *"Amazon Linux"* ]]; then
        echo -e "\e[1;33mInstalling CrowdSec agent on RHEL/CentOS/Amazon Linux\e[0m"
        curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.rpm.sh | sudo bash
        sudo yum install -y crowdsec
    else
        echo "Unsupported Linux distribution"
    fi

elif [ "$OS" == "Darwin" ]; then
    echo -e "\e[1;33mInstalling CrowdSec agent on macOS using Docker\e[0m"
    docker run -d -v acquis.yaml:/etc/crowdsec/acquis.yaml -e COLLECTIONS="crowdsecurity/sshd" -v /var/log/auth.log:/var/log/auth.log -v /path/mycustom.log:/var/log/mycustom.log --name crowdsec crowdsecurity/crowdsec
elif [ "$OS" == "FreeBSD" ]; then
    echo -e "\e[1;33mInstalling CrowdSec agent on FreeBSD\e[0m"
    pkg install crowdsec
else
    echo "Unsupported operating system"
fi

echo -e "\e[1;33mPlease complete the following: \e[0m"
read -p "Enter your enroll token: " ENROLL_TOKEN
sudo cscli console enroll $ENROLL_TOKEN
echo -e "\e[1;33mPlease go back to CrowdSec to accept your enrollment. \e[0m"

CONFIRM='n'
while [[ "$CONFIRM" != "y" ]]; do
  read -p "Have you added your enroll token to the CrowdSec site (y/n)? " CONFIRM
  if [ "$CONFIRM" == "n" ]; then
    echo -e "\e[1;33mWaiting for 90 seconds before asking again... \e[0m"
    sleep 90
  fi
done

echo -e "\e[1;33mScript completed. Executing 'cscli' command in your terminal to verify successful installation... \e[0m"
sleep 5
cscli
