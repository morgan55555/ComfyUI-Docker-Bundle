#!/bin/bash

echo "#####################################################"
echo "##             ComfyUI Launcher script             ##"
echo "#####################################################"
echo

# Fix for libcuda.so.1
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu/

# If pip venv is not created
if [ ! -f "$VENV_DIR_DOCKER/pyvenv.cfg" ]; then
    echo "Pip venv is empty. Trying to create..."
    python3 -m venv "$VENV_DIR_DOCKER"
fi

# Venv is needed for python dependencies, installed by custom nodes.
echo "Activating VENV..."
source "$VENV_DIR_DOCKER/bin/activate"

# Populate folders
folders=("models" "custom_nodes" "input" "output")
for folder in "${folders[@]}"; do
    if [ ! -d "$BASE_DIR_DOCKER/$folder" ]; then
        echo "Populating $folder folder structure..."
        cp -r "$APP_DIR_DOCKER/$folder" "$BASE_DIR_DOCKER/$folder"
    fi
done

# Arguments handling
final_args=("$@")

# Install requirements for ComfyUI
if [ "$(cat "$VENV_DIR_DOCKER/comfyui_version")" != "$COMFYUI_VERSION_DOCKER" ]; then
    echo "Installing reqirements..."
    pip uninstall torch
    pip install torch torchvision torchaudio
    pip install -r "$APP_DIR_DOCKER/requirements.txt"
    echo "$COMFYUI_VERSION_DOCKER" > "$VENV_DIR_DOCKER/comfyui_version"
fi

# Install requirements for manager and set manager args
if [[ "$COMFYUI_MANAGER" == "true" ]]; then
    echo "Manager is enabled!"
    final_args+=("--enable-manager")

    if [ "$(cat "$VENV_DIR_DOCKER/comfyui_mgr")" != "$COMFYUI_VERSION_DOCKER" ]; then
        echo "Installing reqirements..."
        pip install -r "$APP_DIR_DOCKER/manager_requirements.txt"
        echo "$COMFYUI_VERSION_DOCKER" > "$VENV_DIR_DOCKER/comfyui_mgr"
    fi
fi

# Install filebrowser
if [[ "$COMFYUI_FILEBROWSER" == "true" ]]; then
    echo "Filebrowser is enabled!"
    if [ ! -d "$BASE_DIR_DOCKER/custom_nodes/ComfyUI-FileBrowser-iFrame" ]; then
        echo "Installing Filebrowser node!"
        git clone https://github.com/morgan55555/ComfyUI-FileBrowser-iFrame.git "$BASE_DIR_DOCKER/custom_nodes/ComfyUI-FileBrowser-iFrame"
    fi
fi

# Set frontend version
if [[ -n "$COMFYUI_FRONTEND_VERSION" ]]; then
    echo "Selected frontend version $COMFYUI_FRONTEND_VERSION..."
    final_args+=("--front-end-version")
    final_args+=("$COMFYUI_FRONTEND_VERSION")
fi

# Fix for database error (https://github.com/Comfy-Org/ComfyUI/issues/8764)
echo "Applying fix for database error..."
mkdir -p "$BASE_DIR_DOCKER/user"
ln -s "$BASE_DIR_DOCKER/user" "$APP_DIR_DOCKER/user"

# Launch ComfyUI
echo "LD_LIBRARY_PATH is $LD_LIBRARY_PATH"
echo "Launching ComfyUI with arguments "${final_args[@]}"..."
python3 "$APP_DIR_DOCKER/main.py" "${final_args[@]}"
