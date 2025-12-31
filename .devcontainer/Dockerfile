# DevContainer for YouTubeMusicPS PowerShell module development
# Supports Claude Code and Claude Code for Web
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

ARG NODE_VERSION=20
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    sudo \
    ca-certificates \
    gnupg \
    less \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (required for Claude Code CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user with sudo access
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Create directories for PowerShell modules and history persistence
RUN mkdir -p /home/$USERNAME/.local/share/powershell/Modules \
    && mkdir -p /home/$USERNAME/.local/share/powershell/PSReadLine \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.local

# Switch to non-root user
USER $USERNAME
WORKDIR /workspace

# Pre-configure PowerShell: trust PSGallery for faster module installation
RUN pwsh -NoProfile -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"

# Set environment variables
ENV DEVCONTAINER=true
ENV SHELL=/usr/bin/pwsh
