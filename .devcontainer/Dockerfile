# Start from PowerShell base image
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Install wget and curl
RUN apt-get update && \
    apt-get install -y wget curl apt-transport-https lsb-release gnupg 

# Install .NET 8 SDK and runtime
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0

# Install Dapr CLI
RUN wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Install Azure CLI (optional, for debugging)
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli

# Install PowerShell modules (if needed)
RUN pwsh -Command "Install-Module Az -Force -Scope AllUsers"

# Set working directory
WORKDIR /workspace

# Copy Dapr components and function code (devcontainer.json will mount these as volumes)