#!/bin/bash
# test_helpers.sh - Test script for the bash helpers library

# Load helper library
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/bash_helpers.sh"

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    
    log_step "TEST" "Running: $test_name"
    
    if eval "$test_command" 2>/dev/null; then
        log_info "✓ PASSED: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "✗ FAILED: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Core utilities tests
test_core_utilities() {
    log_step "CORE" "Testing core utilities"
    
    # Test logging functions
    run_test "log_info function" "log_info 'Test info message' && true"
    run_test "log_warn function" "log_warn 'Test warning message' && true"
    run_test "log_error function" "log_error 'Test error message' && true"
    run_test "log_debug function" "log_debug 'Test debug message' && true"
    
    # Test utility functions
    run_test "get_current_user function" "test -n \"\$(get_current_user)\""
    run_test "get_distribution function" "test -n \"\$(get_distribution)\""
    run_test "generate_random_string function" "test -n \"\$(generate_random_string 10)\""
    
    # Test validation functions (non-destructive tests)
    run_test "require_command with existing command" "require_command 'bash'"
    
    # Test backup function (create a temp file first)
    run_test "backup_file function" "
        temp_file=\"/tmp/test_backup_\$\$\"
        echo 'test content' > \"\$temp_file\"
        backup_path=\$(backup_file \"\$temp_file\" '/tmp')
        test -f \"\$backup_path\" && rm -f \"\$temp_file\" \"\$backup_path\"
    "
}

# Package manager tests
test_package_manager() {
    log_step "PACKAGE" "Testing package manager functions"
    
    # Test package manager detection
    run_test "detect_package_manager function" "test -n \"\$(detect_package_manager)\""
    
    # Test if package manager detection returns expected values
    local pm=$(detect_package_manager)
    run_test "package manager detection result" "echo '$pm' | grep -E '^(apt|yum|dnf|pacman|zypper|unknown)$'"
}

# Service manager tests
test_service_manager() {
    log_step "SERVICE" "Testing service manager functions"
    
    # Test service manager detection
    run_test "detect_service_manager function" "test -n \"\$(detect_service_manager)\""
    
    # Test if service manager detection returns expected values
    local sm=$(detect_service_manager)
    run_test "service manager detection result" "echo '$sm' | grep -E '^(systemd|sysv|upstart|unknown)$'"
    
    # Test service status check (using a common service)
    if systemctl --version &> /dev/null; then
        run_test "check_service_status function" "test -n \"\$(check_service_status 'dbus')\""
    fi
}

# Web domain tests (non-destructive)
test_web_domain() {
    log_step "WEB" "Testing web domain functions (non-destructive)"
    
    # Test SSL certificate creation in temp directory
    run_test "create_self_signed_cert function (temp)" "
        temp_dir=\"/tmp/ssl_test_\$\$\"
        mkdir -p \"\$temp_dir/certs\" \"\$temp_dir/private\"
        if create_self_signed_cert 'test.local' \"\$temp_dir/certs\" \"\$temp_dir/private\" 1; then
            test -f \"\$temp_dir/certs/test.local.crt\" && test -f \"\$temp_dir/private/test.local.key\"
            rm -rf \"\$temp_dir\"
        else
            rm -rf \"\$temp_dir\"
            false
        fi
    "
}

# System manager tests (non-destructive)
test_system_manager() {
    log_step "SYSTEM" "Testing system manager functions (non-destructive)"
    
    # Test path functions
    run_test "add_to_path function" "
        temp_bashrc=\"/tmp/test_bashrc_\$\$\"
        temp_dir=\"/tmp/test_path_\$\$\"
        mkdir -p \"\$temp_dir\"
        if add_to_path \"\$temp_dir\" \"\$(whoami)\" \"\$temp_bashrc\"; then
            grep -q \"\$temp_dir\" \"\$temp_bashrc\"
            result=\$?
            rm -f \"\$temp_bashrc\"
            rm -rf \"\$temp_dir\"
            test \$result -eq 0
        else
            rm -f \"\$temp_bashrc\"
            rm -rf \"\$temp_dir\"
            false
        fi
    "
}

# Integration tests
test_integration() {
    log_step "INTEGRATION" "Testing integration features"
    
    # Test script template generation
    run_test "generate_script_template function" "
        temp_script=\"/tmp/test_template_\$\$.sh\"
        if generate_script_template \"\$temp_script\" 'Test script' 'false'; then
            test -f \"\$temp_script\" && test -x \"\$temp_script\" && grep -q 'bash_helpers.sh' \"\$temp_script\"
            result=\$?
            rm -f \"\$temp_script\"
            test \$result -eq 0
        else
            rm -f \"\$temp_script\"
            false
        fi
    "
    
    # Test show_available_functions
    run_test "show_available_functions" "
        output=\$(show_available_functions)
        echo \"\$output\" | grep -q 'CORE UTILITIES' && echo \"\$output\" | grep -q 'PACKAGE MANAGEMENT'
    "
}

# Test helper library loading
test_library_loading() {
    log_step "LOADING" "Testing library loading and initialization"
    
    # Test that all main functions are available
    local core_functions=("log_info" "require_command" "get_current_user" "backup_file")
    local package_functions=("detect_package_manager" "install_packages")
    local service_functions=("detect_service_manager" "check_service_status")
    local web_functions=("create_self_signed_cert")
    local system_functions=("add_to_path" "generate_ssh_key")
    
    # Test core functions
    for func in "${core_functions[@]}"; do
        run_test "Function available: $func" "type $func &> /dev/null"
    done
    
    # Test other module functions
    for func in "${package_functions[@]}" "${service_functions[@]}" "${web_functions[@]}" "${system_functions[@]}"; do
        run_test "Function available: $func" "type $func &> /dev/null"
    done
}

# Main test function
main() {
    log_step "START" "Starting bash helpers library tests"
    
    # Test library loading first
    test_library_loading
    
    # Test each module
    test_core_utilities
    test_package_manager
    test_service_manager
    test_web_domain
    test_system_manager
    test_integration
    
    # Print results
    log_step "RESULTS" "Test Results Summary"
    log_info "Tests Run: $TESTS_RUN"
    log_info "Tests Passed: $TESTS_PASSED"
    log_info "Tests Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_info "🎉 All tests passed!"
        exit 0
    else
        log_error "❌ Some tests failed!"
        exit 1
    fi
}

# Check if we need root for some tests
if [ "$1" = "--with-root-tests" ] && [ "$EUID" -ne 0 ]; then
    log_warn "Some tests require root privileges. Re-run with sudo for complete testing."
fi

# Run tests
main "$@"