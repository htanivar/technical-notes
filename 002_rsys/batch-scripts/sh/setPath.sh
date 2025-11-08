#!/bin/bash

# setPath.sh - Dynamic PATH setter with software availability check
# Usage: source setPath.sh in your .bashrc


# Base directory for software installations
OPT_DIR="/apps"

# Directory for soft links
LINK_DIR="/usr/local/bin"

# Software list with their expected subdirectories and executables
declare -A SOFTWARE=(
    ["intellij"]="intellij/bin:idea.sh"
    ["studio"]="android-studio/bin:studio.sh"
    ["webstorm"]="webstorm/bin:webstorm.sh"
    ["pycharm"]="pycharm/bin:pycharm.sh"
    ["goland"]="goland/bin:goland.sh"
    ["go"]="go/bin:go"
    ["flutter"]="flutter/bin:flutter"
    ["java"]="jdk-21.0.9/bin:java"
    ["gradle"]="gradle/gradle-9.2.0/bin:gradle"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create soft link and wrapper script
create_soft_link() {
    local software=$1
    local exec_path=$2
    local link_name="$LINK_DIR/$software"
    
    # Create wrapper script for detached mode
    local wrapper_script="/tmp/${software}_wrapper.sh"
    cat > "$wrapper_script" << EOF
#!/bin/bash
export DISPLAY=:0
nohup "$exec_path" "\$@" > /tmp/${software}_nohup.out 2>&1 &
disown
EOF
    chmod +x "$wrapper_script"
    
    # Create soft link to wrapper (requires sudo)
    if [ -w "$LINK_DIR" ] || sudo -n true 2>/dev/null; then
    sudo ln -sf "$wrapper_script" "$link_name" 2>/dev/null
    if [ $? -eq 0 ]; then
    echo -e "${GREEN}  → Soft link created: $software${NC}"
    else
    echo -e "${YELLOW}  → Could not create soft link (need sudo)${NC}"
    fi
    else
    echo -e "${YELLOW}  → Soft link skipped (need sudo access)${NC}"
    fi
}

# Function to check and add to PATH
#check_and_add_path() {
#    local software=$1
#    local path_info=${SOFTWARE[$software]}
#    local subdir=$(echo $path_info | cut -d':' -f1)
#    local executable=$(echo $path_info | cut -d':' -f2)
#
#    local full_path="$OPT_DIR/$subdir"
#    local exec_path="$full_path/$executable"
#
#    if [ -d "$full_path" ] && [ -f "$exec_path" ]; then
#    export PATH="$full_path:$PATH"
#    echo -e "${GREEN}✓${NC} $software found and added to PATH"
#
#    # Create soft link for detached execution (except for go)
#    if [ "$software" != "go" ]; then
#    create_soft_link "$software" "$exec_path"
#    fi
#
#    # Set specific environment variables
#    case $software in
#    "intellij")
#    export IDEA_HOME="$OPT_DIR/intellij"
#    ;;
#    "studio")
#    export STUDIO_HOME="$OPT_DIR/studio"
#    ;;
#    "webstorm")
#    export WEBSTORM_HOME="$OPT_DIR/webstorm"
#    ;;
#    "pycharm")
#    export PYCHARM_HOME="$OPT_DIR/pycharm"
#    ;;
#    "java")
#    export JAVA_HOME="$OPT_DIR/jdk-21.0.9"
#    ;;
#    "gradle")
#    export GRADLE_HOME="$OPT_DIR/gradle/gradle-9.2.0"
#    ;;
#    "goland")
#    export GOLAND_HOME="$OPT_DIR/goland"
#    ;;
#    "flutter")
#      export FLUTTER_HOME="$OPT_DIR/flutter"
#      ;;
#    "go")
#    export GOROOT="$OPT_DIR/go"
#    export GOPATH="$HOME/go"
#    export PATH=$PATH:$(go env GOPATH)/bin
#    export PATH="$GOPATH/bin:$PATH"
#    ;;
#    esac
#    else
#    echo -e "${RED}✗${NC} $software not found at $full_path"
#    echo -e "${YELLOW}  →${NC} Expected executable: $exec_path"
#    echo -e "${YELLOW}  →${NC} Please download and install $software to $full_path"
#    fi
#}

# Function to check and add to PATH
check_and_add_path() {
    local software=$1
    local path_info=${SOFTWARE[$software]}
    local subdir=$(echo $path_info | cut -d':' -f1)
    local executable=$(echo $path_info | cut -d':' -f2)

    local full_path="$OPT_DIR/$subdir"
    local exec_path="$full_path/$executable"

    if [ -d "$full_path" ] && [ -f "$exec_path" ]; then
        # *** FIX for duplicate PATH entries ***
        # Check if the full_path is ALREADY in the PATH variable
        if ! echo "$PATH" | grep -q "$full_path"; then
            export PATH="$full_path:$PATH"
            echo -e "${GREEN}✓${NC} $software found and added to PATH"
        else
            echo -e "${GREEN}✓${NC} $software found. Already in PATH."
        fi
        # ***********************************

        # Create soft link for detached execution (except for go)
        if [ "$software" != "go" ]; then
            create_soft_link "$software" "$exec_path"
        fi

        # Set specific environment variables (no change needed here)
        case $software in
        # ... (rest of the case statement remains the same)
        "intellij")
            export IDEA_HOME="$OPT_DIR/intellij"
            ;;
        # ...
        "go")
            export GOROOT="$OPT_DIR/go"
            export GOPATH="$HOME/go"
            # Apply the same check for GOPATH/bin
            if ! echo "$PATH" | grep -q "$GOPATH/bin"; then
                export PATH="$GOPATH/bin:$PATH"
            fi
            ;;
        esac
    else
        echo -e "${RED}✗${NC} $software not found at $full_path"
        echo -e "${YELLOW}  →${NC} Expected executable: $exec_path"
        echo -e "${YELLOW}  →${NC} Please download and install $software to $full_path"
    fi
}

# Main execution
echo -e "${YELLOW}Checking software availability in $OPT_DIR...${NC}"

# Check each software
for software in "${(@k)SOFTWARE}"; do
    check_and_add_path "$software"
done

# Additional PATH exports (add your custom paths here)
# export PATH=\"/usr/local/bin:$PATH\"
# export PATH="/usr/local/bin:$PATH"
#Excluding git to validate the owner for the directory
git config --global --add safe.directory /apps/flutter

echo -e "${GREEN}PATH setup complete!${NC}"

# Optional: Show current PATH (uncomment if needed)
# echo -e "\nCurrent PATH:"
# echo $PATH | tr ':' '\n' | nl
