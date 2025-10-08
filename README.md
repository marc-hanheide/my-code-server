# VS-Code Server - Docker Setup & config

## Introduction

This repository hosts a Docker setup for deploying an official installation of Visual Studio Code Server using a container. By leveraging the `serve-web` feature of Visual Studio Code, this setup provides an instance of VS Code accessible through a web browser. The base image used is **Ubuntu**, ensuring a light, stable and familiar environment for development. Included in this setup are a Dockerfile and a docker-compose.yml file, simplifying the deployment process.

This setup now includes **zrok integration** for easy public sharing of your VS Code Server with built-in authentication, making it accessible from anywhere without complex network configurations.

**Note:** This setup aims to maintain compatibility with all Visual Studio Code extensions, including those like GitHub Copilot Chat, by using the official version of VS Code Server. It is designed with the intention to support the full range of VS Code features and extensions without the limitations often encountered in non-official installations.

## Features

- Official VS Code Server installation
- Docker CLI and Docker Compose support inside the container
- GPU support (all GPUs available)
- Non-root user execution for improved security
- Zrok integration for secure public access
- Docker socket mounting for container management
- Persistent data volumes

## Prerequisites

Before you begin, ensure you have the following installed:

- Docker
- Docker Compose (for using the docker-compose.yml)
- (Optional) Zrok account and token for public sharing
- (Optional) Reverse Proxy (for websocket if not using zrok)

## Getting Image

### Pull image from Docker Package Registry

To pull the pre-built image from Docker Package Registry, execute the following command:

```bash
docker pull ghcr.io/marc-hanheide/my-code-server:main
```

### Building the Docker Image

    1. Clone this repository to your local machine.
    2. Navigate to the directory containing the Dockerfile.
    3. Build the Docker image with the following command:

    sudo docker build -t my-code-server:main .

## Running the Container Using Docker Run

**Note:** This setup is designed to work with zrok or a reverse proxy. Direct access via port forwarding is not configured by default. If you want to run the container standalone with port forwarding, you'll need to add the `-p` flag:

```bash
docker run -d -p 8586:8586 -e PORT=8586 my-code-server:main
```

Explanation of flags:

    -d: Run the container in detached mode (in the background).
    -p 8586:8586: Map port 8586 of the host to port 8586 of the container.
    -e PORT=8586: Set the environment variable `PORT` to 8586.

Accessing VS Code Server:

Once the container is running with port forwarding, you can access the VS Code Server by navigating to:

```
http://localhost:8586
```

**Note:** No authentication token is required by default. The VS Code Server runs without connection token authentication in this configuration.

## Starting the VS Code Server with docker compose

Use Docker Compose to start the VS Code server:

1. Navigate to the directory containing the `docker-compose.yml` file.
2. Create and configure your `.env` file (see Configuration section below).
3. Run the following command:

```bash
docker compose up -d
```

**Note:** The VS Code server is **not accessible directly** via localhost. Access is provided through:
- **Zrok tunnel** (recommended) - provides public access with authentication
- **Nginx reverse proxy** - for custom domain and SSL setup

The container does not expose ports directly for security reasons. All access is through zrok or your reverse proxy configuration.

## Configuration

### Environment Variables for .env File

Create a `.env` file in the same directory as your `docker-compose.yml` file. You can use the provided `example.env` as a template:

```bash
cp example.env .env
```

Then edit `.env` with your actual values:

| Variable | Description | Required |
|----------|-------------|----------|
| `ZROK_ENV_NAME` | Environment name for your zrok instance (e.g., `vscode@hostname`) | Yes |
| `ZROK_NAME` | Name for your zrok service | Yes |
| `ZROK_API_ENDPOINT` | Zrok API endpoint URL | Yes |
| `ZROK_TOKEN` | Your zrok authentication token | Yes |
| `ZROK_BASICAUTH` | Basic authentication for zrok (format: `username:password`) | Yes |

### Docker Compose Configuration

- **Internal port**: `8586` (not exposed to host - access via zrok or reverse proxy only)
- **No port forwarding**: The container does not expose ports directly for security
- **No token authentication**: VS Code Server runs without connection token by default (security provided by zrok basic auth)
- **Data persistence**: Docker volumes `user_data` and `zrok-data` store all persistent data
- **Docker socket**: Mounted at `/var/run/docker.sock` for container management from within VS Code
- **GPU support**: Enabled by default (all GPUs available)

## Environment Variables for VS Code Server

The following environment variables can be configured in the `docker-compose.yml` file:

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | The port on which VS Code Server will listen (internal only) | `8586` |
| `HOST` | The host interface to listen on | `0.0.0.0` |
| `SERVER_DATA_DIR` | Directory where server data is stored | `/home/vscodeuser/.local/share/server_data_dir` |
| `CLI_DATA_DIR` | Directory where CLI metadata should be stored | `/home/vscodeuser/.local/share/cli_data_dir` |
| `DOCKER_GROUP` | Docker group ID for socket access (optional) | - |

**Note:** The following VS Code Server variables are supported by the `start.sh` script but not used in the default configuration:
- `TOKEN` / `TOKEN_FILE` - Connection token for authentication (not used by default)
- `SERVER_BASE_PATH` - Path under which the web UI is provided
- `SOCKET_PATH` - Socket path for the server
- `VERBOSE` - Enable verbose output
- `LOG_LEVEL` - Log level (trace, debug, info, warn, error, critical, off)

## Zrok Integration (Default Access Method)

This setup is **designed primarily for zrok** - a secure tunneling service that provides public access to your VS Code Server without port forwarding or complex network configurations.

### What is Zrok?

Zrok is a secure tunneling service that allows you to share services publicly with built-in authentication. It's similar to ngrok but can be self-hosted or used with public instances. This is the **recommended and default way** to access your VS Code Server.

### Setting Up Zrok

1. **Get a Zrok Account**: Sign up at your zrok instance (e.g., https://zrok.example.com)
2. **Get Your Token**: Once registered, obtain your authentication token from your account
3. **Configure Environment Variables**: Update your `.env` file with your zrok credentials
4. **Start the Services**: Run `docker compose up -d`

The zrok container will:
- Automatically enable and configure zrok on startup
- Create a reserved public share with basic authentication
- Keep your VS Code Server accessible via a public URL
- Properly clean up on shutdown

### Accessing via Zrok

Once running, zrok will provide a public URL (check the zrok service logs):
```bash
docker compose logs zrok
```

Access your VS Code Server via the zrok public URL with the credentials specified in `ZROK_BASICAUTH`.

## Alternative: Nginx Reverse Proxy Configuration

If you prefer not to use zrok, you can set up a traditional reverse proxy with Nginx to access the VS Code Server securely with a domain name and SSL. 

**Important:** When using Nginx instead of zrok, you'll need to either:
1. Add port forwarding in `docker-compose.yml` by uncommenting/adding a `ports:` section to the vscode-server service, OR
2. Keep both services on the same Docker network (already configured as `vscode-server-network`)

### Network Configuration

- The container uses the `vscode-server-network` network.
- The container name is `my-code-server`.
- Default internal port is `8586`.

### Configuring Nginx HTTP exemple

```nginx
# my code server
server {
    listen 80;
    server_name my-code-server.domain.com;

    location / {
        set $codeservervar my-code-server.vscode-server-network:8586;
        proxy_pass http://$codeservervar;  
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Configuring Nginx HTTPS/SSL exemple

```nginx
# my code server
server {
    listen 443 ssl;
    server_name my-code-server.domain.com;

    ssl_certificate /ssl/.domain.com.cer;
    ssl_certificate_key /ssl/.domain.com.key;

    location / {
        set $codeservervar my-code-server.vscode-server-network:8586;
        proxy_pass http://$codeservervar;    
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### SSL Certificates

Make sure to have valid SSL certificates for 443 ssl usage.

### Accessing VS Code Server via Nginx

Access via `https://my-code-server.domain.com`

**Note:** No token parameter is needed as the default configuration runs without VS Code authentication tokens.

## Docker and GPU Support

This setup includes:
- **Docker CLI** and **Docker Compose** installed inside the container
- **Docker socket mounting** (`/var/run/docker.sock`) for managing containers from within VS Code
- **GPU support** enabled (all available GPUs are accessible)
- **Non-root user** (`vscodeuser`) with sudo privileges for improved security

## Security Note

**Important Security Considerations:**
- **No direct port exposure**: The default configuration does not expose ports to the host, reducing attack surface
- **Zrok provides authentication**: Access control is managed through zrok's basic authentication
- **No VS Code token authentication**: The server runs without connection tokens by default - security is provided by zrok
- Replace all passwords and tokens with secure values
- Never commit your `.env` file to version control (add it to `.gitignore`)
- Use strong passwords for `ZROK_BASICAUTH` - this is your primary authentication layer
- Keep your `ZROK_TOKEN` secret and rotate it regularly
- The Docker socket mounting provides full container management capabilities - use with caution
- If you need to add port forwarding for direct access, consider adding VS Code token authentication for additional security

## Contributing

Contributions are welcome!
