#!/bin/bash

# Function to install Docker
install_docker() {
    echo "Setting up Docker's apt repository..."

    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update apt and install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Verify Docker installation
    echo "Verifying Docker installation..."
    docker -v
    docker-compose -v
}

# Check if Docker is installed
echo "Checking if Docker is installed..."
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed. Installing Docker..."
    install_docker
else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed
echo "Checking Docker Compose version..."
if ! command -v docker-compose &>/dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo apt-get install -y docker-compose
else
    echo "Docker Compose is already installed."
fi

# Add user to Docker group to avoid using sudo with Docker commands
if ! groups $USER | grep &>/dev/null "\bdocker\b"; then
    echo "Adding $USER to the Docker group..."
    sudo usermod -aG docker $USER
    echo "User added to Docker group. Starting new shell to apply changes."
    newgrp docker # Applies the group changes immediately without needing to log out
else
    echo "$USER is already in the Docker group."
fi


# Function to generate random string of letters and digits
generate_random_string() {
    local length=20
    local characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result=""
    for i in $(seq 1 $length); do
        result="$result${characters:RANDOM%${#characters}:1}"
    done
    echo $result
}

# Clone the repository
echo "Cloning the Evolution API Dockerized repository..."
git clone https://github.com/devalexcode/docker-evolution-api.git
cd docker-evolution-api

# Create .env file from .env.example
echo "Creating .env file..."
cp .env.example .env

# Generate random environment variables
AUTHENTICATION_API_KEY=$(generate_random_string)
POSTGRESS_USER=$(generate_random_string)
POSTGRESS_PASS=$(generate_random_string)

# Replace values in the .env file
echo "Updating .env file with generated values..."
sed -i "s/^AUTHENTICATION_API_KEY=.*/AUTHENTICATION_API_KEY=$AUTHENTICATION_API_KEY/" .env
sed -i "s/^POSTGRESS_USER=.*/POSTGRESS_USER=$POSTGRESS_USER/" .env
sed -i "s/^POSTGRESS_PASS=.*/POSTGRESS_PASS=$POSTGRESS_PASS/" .env

# Open the .env file for review (optional)
echo "Opening .env file for review. Please verify the values."
nano .env

# Run Docker Compose to raise services in detached mode
echo "Raising services with Docker Compose..."
docker-compose up -d

# Wait for a few seconds to ensure the containers are starting
sleep 5

# Verify that the containers are up and running
echo "Verifying that the containers are running..."
docker ps

# Optionally expose the Evolution API port using UFW (if firewall is active)
echo "Do you want to expose the Evolution API port using UFW? (e.g. 8080) [y/n]"
read -p "Enter 'y' to expose port, 'n' to skip: " expose_port
if [ "$expose_port" == "y" ]; then
    echo "Allowing port 8080 on UFW firewall..."
    sudo ufw allow 8080
    echo "Port 8080 is now open."
    sudo ufw status
fi

# Final message
echo "Evolution API Dockerized setup is complete. Access the API at http://localhost:8080/manager or http://<your-server-ip>:8080/manager."
echo "You may need to configure the firewall and access settings depending on your server's setup."
