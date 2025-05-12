Okay, here's a bash script to automate the setup of the Evolution API Docker project on a Linux VPS.

This script will:

Check for Docker and Docker Compose.

Offer to install them (using apt for Debian/Ubuntu, with a strong recommendation to follow official docs if that fails or for other distros).

Offer to add the current user to the docker group.

Clone the repository.

Prompt the user for the necessary .env variables.

Create and populate the .env file.

Start the services with docker compose up -d.

Show running containers.

Optionally, if UFW is active, prompt to open the Evolution API port.

#!/bin/bash

# Script to automate the setup of Dockerized Evolution API

# Exit on any error, treat unset variables as an error, and propagate exit status through pipes
set -e
set -u
set -o pipefail

# --- Configuration ---
REPO_URL="https://github.com/devalexcode/docker-evolution-api.git"
PROJECT_DIR="docker-evolution-api"
ENV_EXAMPLE_FILE=".env.example"
ENV_FILE=".env"

# --- Helper Functions ---
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
info() { echo -e "\033[34mINFO: $1\033[0m"; }
ask() {
    local prompt default reply
    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do
        read -p "$1 [$prompt] " reply
        if [ -z "$reply" ]; then
            reply=$default
        fi
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

# --- Main Script ---

info "Starting Evolution API Dockerized Setup..."

# 1. Check for Docker and Docker Compose
info "Checking for Docker and Docker Compose..."
DOCKER_INSTALLED=true
DOCKER_COMPOSE_INSTALLED=true

if ! command -v docker &> /dev/null; then
    red "Docker could not be found."
    DOCKER_INSTALLED=false
fi

if ! docker compose version &> /dev/null; then
    red "Docker Compose (plugin) could not be found."
    DOCKER_COMPOSE_INSTALLED=false
fi

# 2. Install Docker and Docker Compose if not found (Debian/Ubuntu specific)
if ! $DOCKER_INSTALLED || ! $DOCKER_COMPOSE_INSTALLED; then
    yellow "Docker and/or Docker Compose are not installed."
    if ask "Attempt to install them using apt (recommended for Debian/Ubuntu)? (N for manual install)" "N"; then
        info "Updating package lists..."
        sudo apt update -y

        if ! $DOCKER_INSTALLED; then
            info "Installing Docker Engine..."
            sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update -y
            sudo apt install -y docker-ce docker-ce-cli containerd.io
            green "Docker Engine installed."
        fi

        if ! $DOCKER_COMPOSE_INSTALLED; then
            info "Installing Docker Compose plugin..."
            sudo apt install -y docker-compose-plugin
            green "Docker Compose plugin installed."
        fi

        # Verify again
        if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
            red "Installation failed or components still not found. Please install Docker and Docker Compose manually."
            info "Docker Engine: https://docs.docker.com/engine/install/"
            info "Docker Compose: https://docs.docker.com/compose/install/"
            exit 1
        fi
    else
        red "Please install Docker and Docker Compose manually and re-run this script."
        info "Docker Engine: https://docs.docker.com/engine/install/"
        info "Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
fi
green "Docker and Docker Compose are available."

# 3. Add user to docker group (optional)
if ! groups $(whoami) | grep -q '\bdocker\b'; then
    yellow "Your user ($(whoami)) is not in the 'docker' group."
    if ask "Add $(whoami) to the 'docker' group to avoid using sudo with docker commands? (Requires logout/login or new shell)" "Y"; then
        sudo usermod -aG docker $(whoami)
        green "$(whoami) added to the docker group."
        yellow "IMPORTANT: You need to log out and log back in, or start a new shell for this change to take effect."
        yellow "Alternatively, you can run 'newgrp docker' in your current shell, but it might not be fully effective."
        if ask "Continue with the script anyway (you might need to use sudo manually for docker commands if group change isn't active yet)?" "Y"; then
            info "Continuing..."
        else
            info "Exiting. Please log out/in and re-run."
            exit 0
        fi
    fi
fi

# 4. Clone the repository
if [ -d "$PROJECT_DIR" ]; then
    yellow "Project directory '$PROJECT_DIR' already exists."
    if ask "Do you want to remove it and re-clone?" "N"; then
        info "Removing existing directory: $PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
        info "Cloning repository: $REPO_URL"
        git clone "$REPO_URL"
    else
        info "Using existing directory: $PROJECT_DIR. Attempting to update..."
        cd "$PROJECT_DIR"
        git pull || (red "Failed to pull updates. Please check the directory or remove it manually." && exit 1)
        cd .. # Go back to parent for consistency
    fi
else
    info "Cloning repository: $REPO_URL"
    git clone "$REPO_URL"
fi
cd "$PROJECT_DIR"
green "Repository cloned into $PROJECT_DIR."

# 5. Create the .env file
info "Creating .env file from $ENV_EXAMPLE_FILE..."
if [ -f "$ENV_FILE" ]; then
    yellow "$ENV_FILE already exists."
    if ! ask "Overwrite $ENV_FILE with new configuration?" "Y"; then
        info "Using existing $ENV_FILE. Skipping configuration prompts."
        # Attempt to read existing EVOLUTION_API_PORT for UFW step later
        # This is a best-effort attempt and might not be robust if .env is malformed
        EVOLUTION_API_PORT_CONFIGURED=$(grep -E "^EVOLUTION_API_PORT=" "$ENV_FILE" | cut -d'=' -f2) || EVOLUTION_API_PORT_CONFIGURED="8080"
    else
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        configure_env_file=true
    fi
else
    cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
    configure_env_file=true
fi

# 6. Configure the .env file
if [[ "${configure_env_file:-false}" == true ]]; then
    info "Please provide the following configuration values for .env:"

    default_api_key="your_strong_api_key_here" # Provide a more descriptive placeholder
    read -p "Enter AUTHENTICATION_API_KEY (e.g., $default_api_key): " AUTHENTICATION_API_KEY
    AUTHENTICATION_API_KEY=${AUTHENTICATION_API_KEY:-$default_api_key}

    default_evo_port="8080"
    read -p "Enter EVOLUTION_API_PORT (default: $default_evo_port): " EVOLUTION_API_PORT
    EVOLUTION_API_PORT=${EVOLUTION_API_PORT:-$default_evo_port}
    EVOLUTION_API_PORT_CONFIGURED=$EVOLUTION_API_PORT # Save for UFW

    default_redis_port="6379"
    read -p "Enter REDIS_PORT (default: $default_redis_port): " REDIS_PORT
    REDIS_PORT=${REDIS_PORT:-$default_redis_port}

    default_pg_port="5432"
    read -p "Enter POSTGRES_PORT (default: $default_pg_port): " POSTGRES_PORT
    POSTGRES_PORT=${POSTGRES_PORT:-$default_pg_port}

    default_pg_user="evo_user"
    read -p "Enter POSTGRES_USER (default: $default_pg_user - CHANGE THIS!): " POSTGRES_USER
    POSTGRES_USER=${POSTGRES_USER:-$default_pg_user}

    default_pg_pass=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 20)
    read -p "Enter POSTGRES_PASS (default: $default_pg_pass - CHANGE THIS!): " POSTGRES_PASS
    POSTGRES_PASS=${POSTGRES_PASS:-$default_pg_pass}

    # Update .env file
    # Using | as sed delimiter to avoid issues with passwords containing /
    sed -i.bak \
        -e "s|^AUTHENTICATION_API_KEY=.*|AUTHENTICATION_API_KEY=${AUTHENTICATION_API_KEY}|" \
        -e "s|^EVOLUTION_API_PORT=.*|EVOLUTION_API_PORT=${EVOLUTION_API_PORT}|" \
        -e "s|^REDIS_PORT=.*|REDIS_PORT=${REDIS_PORT}|" \
        -e "s|^POSTGRES_PORT=.*|POSTGRES_PORT=${POSTGRES_PORT}|" \
        -e "s|^POSTGRES_USER=.*|POSTGRES_USER=${POSTGRES_USER}|" \
        -e "s|^POSTGRES_PASS=.*|POSTGRES_PASS=${POSTGRES_PASS}|" \
        "$ENV_FILE"
    rm -f "${ENV_FILE}.bak" # Remove backup file on success
    green ".env file configured."
    yellow "IMPORTANT: Review the generated .env file, especially passwords, and store them securely."
    cat "$ENV_FILE"
    echo "" # Newline
else
    # Ensure EVOLUTION_API_PORT_CONFIGURED is set if we skipped prompts
    if [ -z "${EVOLUTION_API_PORT_CONFIGURED:-}" ]; then
        EVOLUTION_API_PORT_CONFIGURED=$(grep -E "^EVOLUTION_API_PORT=" "$ENV_FILE" | cut -d'=' -f2) || EVOLUTION_API_PORT_CONFIGURED="8080"
    fi
fi


# 7. Raise the services
info "Starting services with 'docker compose up -d'..."
if docker compose up -d; then
    green "Services started successfully in detached mode."
else
    red "Failed to start services with docker compose. Check the output above for errors."
    exit 1
fi

# 8. Verify that the containers are running
info "Verifying running containers (docker ps)..."
docker ps

# 9. Access to the application
SERVER_IP=$(hostname -I | awk '{print $1}') # Get primary IP
green "Evolution API should be accessible soon."
info "Access from browser (or curl) at: http://${SERVER_IP}:${EVOLUTION_API_PORT_CONFIGURED}/manager"
info "If on localhost, you can use: http://localhost:${EVOLUTION_API_PORT_CONFIGURED}/manager"
info "Use the AUTHENTICATION_API_KEY you configured in the 'API Key Global' field."

# 10. Expose the Evolution API port (optional) with UFW
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        yellow "UFW (firewall) is active."
        if ask "Do you want to allow port ${EVOLUTION_API_PORT_CONFIGURED} through UFW for external access?" "Y"; then
            info "Allowing port ${EVOLUTION_API_PORT_CONFIGURED}..."
            sudo ufw allow "${EVOLUTION_API_PORT_CONFIGURED}/tcp"
            sudo ufw status
            green "Port ${EVOLUTION_API_PORT_CONFIGURED} allowed in UFW."
        else
            info "Port ${EVOLUTION_API_PORT_CONFIGURED} not opened in UFW. API might only be accessible locally or within Docker network."
        fi
    else
        info "UFW is installed but not active. No firewall changes made."
    fi
else
    info "UFW is not installed. No firewall changes made. Ensure your VPS firewall (if any) allows traffic on port ${EVOLUTION_API_PORT_CONFIGURED} if you need external access."
fi

green "Setup script finished!"
info "Remember to check the logs if you encounter issues: docker compose logs -f evolution_api"
info "Data is typically stored in volumes managed by Docker. Check docker-compose.yml for volume definitions (e.g., ./data/postgres, ./data/evolution_api)."

cd .. # Return to the original directory
exit 0


How to use the script:

Save: Save the code above into a file, for example, setup_evolution_api.sh.

Make executable: chmod +x setup_evolution_api.sh

Run: ./setup_evolution_api.sh

Explanation and Features:

Error Handling (set -e -u -o pipefail): Makes the script more robust by exiting on errors.

Helper Functions: For colored output (green, yellow, red, info) and user prompts (ask).

Dependency Checks: Verifies docker and docker compose.

Automated Installation (Optional): Offers to install Docker and Docker Compose using apt for Debian/Ubuntu systems. For other systems, it will guide the user to manual installation.

User Group Management: Offers to add the current user to the docker group.

Repository Cloning: Clones the project. If the directory exists, it asks to remove and re-clone or attempt a git pull.

.env Configuration:

Copies .env.example to .env.

If .env already exists, it asks to overwrite or use the existing one.

Prompts the user for each required variable (AUTHENTICATION_API_KEY, EVOLUTION_API_PORT, etc.).

Provides defaults (and a randomly generated password for PostgreSQL as a suggestion, which the user should definitely change or confirm).

Uses sed to update the .env file non-interactively based on user input.

Service Startup: Runs docker compose up -d.

Verification: Runs docker ps to show running containers.

Access Information: Displays the URL to access the application, attempting to detect the server's IP.

UFW Firewall (Optional):

Checks if ufw is installed and active.

If active, prompts the user if they want to allow the EVOLUTION_API_PORT through the firewall.

Idempotency Considerations: The script tries to handle cases where it's run multiple times (e.g., existing project directory, existing .env file).

User Guidance: Provides informative messages throughout the process.

This script should significantly streamline the setup process on a fresh Linux VPS. Remember to review the generated .env file, especially the passwords, and store them securely.
