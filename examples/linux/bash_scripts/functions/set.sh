#!/bin/bash

# Function to set the user directory based on the operating system
set_user_directory() {
  case "$(uname -s)" in
    Linux*)
      user_directory="$HOME"
      echo "Operating System: Linux"
      echo "User Directory: $user_directory"
      ;;
    MINGW* | CYGWIN* | MSYS*)
      user_directory="$USERPROFILE"
      echo "Operating System: Windows"
      echo "User Directory: $user_directory"
      ;;
    *)
      echo "Warning: Unsupported operating system detected."
      exit 1
      ;;
  esac
}

