#!/bin/bash
# this File is part of OpenVPN-WebAdmin - (c) 2020 OpenVPN-WebAdmin

# [Previous content preserved...]

test_system(){
  message_print_out i "Checking system requirements and dependencies..."

  # Define required packages with their optional dependencies
  declare -A pkg_deps
  pkg_deps=(
    ["openvpn"]=""
    ["php"]="php-mysql php-zip php-json php-mbstring php-xml php-curl"
    ["mysql"]="mysql-client"
    ["yarn"]="nodejs npm"
    ["wget"]="curl"
    ["unzip"]="tar gzip"
    ["route"]="net-tools"
  )

  # Track missing packages
  missing_packages=""
  missing_deps=""

  # Check each main package and its dependencies
  for pkg in "${!pkg_deps[@]}"; do
    # Check main package
    if ! command -v $pkg >/dev/null 2>&1; then
      missing_packages="$missing_packages $pkg"
      # If package is missing, check its dependencies
      if [ -n "${pkg_deps[$pkg]}" ]; then
        for dep in ${pkg_deps[$pkg]}; do
          if ! command -v $dep >/dev/null 2>&1; then
            missing_deps="$missing_deps $dep"
          fi
        done
      fi
    fi
  done

  # If there are missing packages, attempt to install them
  if [ -n "$missing_packages" ] || [ -n "$missing_deps" ]; then
    message_print_out i "The following packages need to be installed:${COL_LIGHT_RED}${missing_packages}${missing_deps}${COL_NC}"
    
    # Update package lists first
    if [ "${OS}" == "debian" ]; then
      if ! apt-get update -y >> ${CURRENT_PATH}/loginstall.log 2>&1; then
        message_print_out 0 "Failed to update package lists. Check your internet connection and apt sources."
        message_print_out 0 "${BREAK}"
        return 1
      fi
    elif [ "${OS}" == "centos" ]; then
      if ! yum check-update >> ${CURRENT_PATH}/loginstall.log 2>&1; then
        message_print_out 0 "Failed to update package lists. Check your internet connection and yum repositories."
        message_print_out 0 "${BREAK}"
        return 1
      fi
    fi

    # Install missing packages
    if [ "${OS}" == "debian" ]; then
      # Special handling for PHP packages
      if [[ "$missing_packages $missing_deps" =~ "php" ]]; then
        if ! apt-get install -y php php-mysql php-zip php-json php-mbstring php-xml php-curl >> ${CURRENT_PATH}/loginstall.log 2>&1; then
          message_print_out 0 "Failed to install PHP and its extensions."
          message_print_out 0 "${BREAK}"
          return 1
        fi
      fi

      # Install other packages
      for pkg in $missing_packages $missing_deps; do
        if [ "$pkg" != "php" ] && [ "${pkg:0:3}" != "php-" ]; then
          if ! apt-get install -y $pkg >> ${CURRENT_PATH}/loginstall.log 2>&1; then
            message_print_out 0 "Failed to install ${pkg}. Check package availability."
            message_print_out 0 "${BREAK}"
            return 1
          fi
        fi
      done
    elif [ "${OS}" == "centos" ]; then
      # Special handling for PHP packages
      if [[ "$missing_packages $missing_deps" =~ "php" ]]; then
        if ! yum install -y php php-mysqlnd php-zip php-json php-mbstring php-xml php-curl >> ${CURRENT_PATH}/loginstall.log 2>&1; then
          message_print_out 0 "Failed to install PHP and its extensions."
          message_print_out 0 "${BREAK}"
          return 1
        fi
      fi

      # Install other packages
      for pkg in $missing_packages $missing_deps; do
        if [ "$pkg" != "php" ] && [ "${pkg:0:3}" != "php-" ]; then
          if ! yum install -y $pkg >> ${CURRENT_PATH}/loginstall.log 2>&1; then
            message_print_out 0 "Failed to install ${pkg}. Check package availability."
            message_print_out 0 "${BREAK}"
            return 1
          fi
        fi
      done
    fi

    message_print_out 1 "Successfully installed missing packages."
  else
    message_print_out 1 "All required packages are already installed."
  fi

  # Verify installations
  for pkg in "${!pkg_deps[@]}"; do
    if ! command -v $pkg >/dev/null 2>&1; then
      message_print_out 0 "Failed to verify installation of ${pkg}."
      message_print_out 0 "${BREAK}"
      return 1
    fi
  done

  return 0
}

