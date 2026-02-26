ARG BASE_IMAGE=nvidia/cuda:13.0.0-cudnn-devel-ubuntu22.04

# From selected image
FROM "$BASE_IMAGE"

# Define build arguments
ARG USER_NAME=runner
ARG USER_UID=1001
ARG USER_GID=1001

ARG WORKING_DIR=/comfy
ARG APP_DIR=$WORKING_DIR/app
ARG BASE_DIR=$WORKING_DIR/base
ARG VENV_DIR=$WORKING_DIR/base/.env

ARG COMFYUI_VERSION=master
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu130

# Some fixes
ENV DEBIAN_FRONTEND=noninteractive
ENV UV_LINK_MODE=copy

# Set environment variables
ENV COMFYUI_MANAGER true
ENV COMFYUI_FILEBROWSER true

# ENV COMFYUI_FRONTEND_VERSION Comfy-Org/ComfyUI_frontend@latest

ENV FILEBROWSER_URL http://127.0.0.1:8080/

# Install required packages
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        git python3 python3-pip python3-venv python3-dev libxcb1 libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create the group and user
RUN groupadd --gid "$USER_GID" "$USER_NAME" && \
    useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USER_NAME" -s /bin/bash

# Set the working directory
WORKDIR "$WORKING_DIR"

# Populate folder structure
RUN mkdir -p "$VENV_DIR" "$APP_DIR" "$BASE_DIR" && \
    chown -R $USER_UID:$USER_GID "$WORKING_DIR" "$VENV_DIR" "$APP_DIR" "$BASE_DIR"

# Copy startup script
COPY --chown=$USER_UID:$USER_GID --chmod=0755 launch.sh ./launch.sh

# Switch to the non-root user
USER $USER_NAME

# Clone repo
RUN git clone https://github.com/Comfy-Org/ComfyUI.git --depth 1 --single-branch --branch "$COMFYUI_VERSION" "$APP_DIR" 

# Set additional environment variables from build arguments
ENV VENV_DIR_DOCKER=${VENV_DIR}
ENV APP_DIR_DOCKER=${APP_DIR}
ENV BASE_DIR_DOCKER=${BASE_DIR}
ENV COMFYUI_VERSION_DOCKER=${COMFYUI_VERSION}

# Set pip index url
RUN pip config set user.index-url "$TORCH_INDEX_URL"

# Run launch script
ENTRYPOINT ./launch.sh --listen 0.0.0.0 --port 8188 --disable-auto-launch --base-directory "$BASE_DIR_DOCKER"