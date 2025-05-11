# 🐧 Evolution API Dockerized for Linux VPS

This project is based on the official repository of [Evolution API](https://github.com/EvolutionAPI/evolution-api), a solution for sending WhatsApp messages through a simple and powerful API.

This environment includes:

- Evolution API
- Redis
- PostgreSQL
- Configurable environment variables
- Clear documentation for exposing ports and securing the service

> Ideal for those who wish to have the Evolution API running on a VPS for minutes, without complicated configurations and manual installations.

---

## ✅ Requirements

Make sure you have installed:

````bash
docker -v
docker compose version
````

If you don't have them, you can install them with:

- [Docker Engine](https://docs.docker.com/engine/install/)
- Docker Compose Plugin](https://docs.docker.com/compose/install/)

It is also recommended to add your user to the `docker` group to avoid using `sudo`:

- [Post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/)

## 🚀 Installing the project

### 1. Clone this repository

```bash
git clone https://github.com/devalexcode/docker-evolution-api.git
cd docker-evolution-api
````

### 2. Create the `.env` file

````bash
cp .env.example .env
````

## ⚙️ Configuring the `.env` file

Before you start up the services, make sure you create and configure your `.env` file:

````bash
# Open the code editor to edit the defaults
nano .env
````

Edit the `.env` file with your own values:

````dotenv
# 🔐 EVOLUTION API
AUTHENTICATION_API_KEY=tu_key_api_here # Authentication key for the Evolution API
EVOLUTION_API_PORT=8080 # Port where the API will be exposed (if you have another application running on this port change this value)

# 🧠 REDIS
REDIS_PORT=6379 # Default Redis port

# 🐘 POSTGRESQL
POSTGRESS_PORT=5432 # PostgreSQL default port
POSTGRESS_USER=postgres_user # Database user (FOR SECURITY SAFETY SAFETY CHANGE THIS VALUE)
POSTGRESS_PASS=secure_key # User password (FOR SECURITY SAFETY CHANGE THIS VALUE)
````.

### 3. Raise the services

````bash
docker compose up -d
````

This command:

- Builds the necessary images.
- Pull up the containers defined in ``docker-compose.yml``.
- Everything in the background (`-d`)

---

## 📦 Verifies that the container is running

After raising the environment with `docker compose up -d`, you can verify that the Evolution API is running correctly with:

````bash
docker ps
````

You should see output similar to this:

````bash
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
e3b6d8e6c317 atendai/evolution-api:latest "/bin/bash -c '. ./D..."   28 seconds ago Up 26 seconds 0.0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp evolution_api
````

---

## 🌐 Access to the application

Access from browser (or use `curl`) at:

```
http://IP_DEL_SERVIDOR:8080/manager
````

Evolution API environment diagram](docs/login.png)

> Enter in the API Key Global field the value you assigned in the .env file 
> Replace `8080` with the configured port if you used another one.  
> If you are on localhost, you can use `http://localhost:8080/manager`.

---

## 🔐 Expose the Evolution API port (optional)

If you are on a Linux server with `ufw` (firewall) enabled, you can expose only the port needed to access the Evolution API from outside.

### ✅ Allow only the port defined in `.env` (e.g. 8080)

````bash
sudo ufw allow 8080
````

> Make sure the value of `EVOLUTION_API_PORT` in your `.env` matches the port you are opening.

### 🔍 Verify that the port is allowed

````bash
sudo ufw status
````

You should see a rule like:

````
8080 ALLOW Anywhere
````

> ⚠️ Don't open ports you don't need from the outside. If you are only going to consume the API locally (inside the same Docker container or network), **you don't need to open the port with UFW**.

---

## 👨‍💻 Author

Developed by [Alejandro Robles | Devalex ](http://devalexcode.com) 
Need me to do it for you? I'm here to support you! 🤝 http://devalexcode.com/soluciones/evolution-api-whatsapp-en-servidor-vps

Doubts or suggestions? contributions welcome!
