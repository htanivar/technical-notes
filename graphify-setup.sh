#!/bin/bash

# Ensure user-installed binaries are in PATH
export PATH="$HOME/.local/bin:$PATH"

# Configuration
PROJECT_DIR="${1:-.}"  # Allow passing project directory as argument
GRAPHIFY_OUTPUT="graphify-out"
CACHE_DIR="$GRAPHIFY_OUTPUT/cache"
TOKEN_LIMIT_PER_MIN=200000  # Conservative limit (25% below 250k)
TOKEN_WINDOW=60  # 60 second window
BATCH_SIZE=5  # Number of files to process per batch

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_token_info() {
    echo -e "${CYAN}[TOKENS]${NC} $1"
}

print_progress() {
    echo -e "${MAGENTA}[PROGRESS]${NC} $1"
}

# Function to estimate tokens (rough estimate: 4 chars ≈ 1 token)
estimate_tokens() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local char_count=$(wc -c < "$file_path" 2>/dev/null || echo 0)
        echo $((char_count / 4))
    else
        echo 0
    fi
}

# Function to get file size in a human-readable format
get_file_size() {
    if command -v numfmt &> /dev/null; then
        du -b "$1" 2>/dev/null | cut -f1 | numfmt --to=si
    else
        du -h "$1" 2>/dev/null | cut -f1
    fi
}

# Function to check if a file or directory is ignored by git
is_ignored() {
    local path="$1"
    if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
        git check-ignore -q "$path" 2>/dev/null
        return $?
    else
        # Fallback basic checks if not in a git repo
        if [[ "$path" == *"/.git"* || "$path" == *"/node_modules"* || "$path" == *"/graphify-out"* || "$path" == ".git" || "$path" == "node_modules" || "$path" == "graphify-out" ]]; then
            return 0
        fi
        return 1
    fi
}

# Function to check if we should process a file based on size
should_process_file() {
    local file_path="$1"
    local max_size_mb=5  # Skip files larger than 5MB
    
    if [ -f "$file_path" ]; then
        if is_ignored "$file_path"; then
            return 1  # Don't process
        fi
        local size_bytes=$(wc -c < "$file_path" 2>/dev/null || echo 0)
        local size_mb=$((size_bytes / 1048576))
        if [ $size_mb -gt $max_size_mb ]; then
            return 1  # Don't process
        fi
    fi
    return 0  # Process
}

# Function to get sorted list of files by size (smallest first)
get_files_sorted_by_size() {
    local directory="$1"
    local pattern="${2:-*.py,*.js,*.ts,*.go,*.rs,*.java,*.cpp,*.c,*.h,*.rb,*.php,*.cs}"
    
    local all_found_files
    all_found_files=$(find "$directory" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" -o -name "*.h" -o -name "*.rb" -o -name "*.php" -o -name "*.cs" \) 2>/dev/null)
    
    if [ -z "$all_found_files" ]; then
        return 0
    fi
    
    local filtered_files
    if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
        local ignored_files
        ignored_files=$(echo "$all_found_files" | git check-ignore --stdin --no-index 2>/dev/null)
        filtered_files=$(awk 'NR==FNR {ignored[$0]=1; next} !ignored[$0]' <(echo "$ignored_files") <(echo "$all_found_files"))
    else
        filtered_files="$all_found_files"
    fi
    
    if [ -z "$filtered_files" ]; then
        return 0
    fi
    
    echo "$filtered_files" | while read -r file; do
        if [ -n "$file" ] && should_process_file "$file"; then
            echo "$(wc -c < "$file" 2>/dev/null || echo 0) $file"
        fi
    done | sort -n | cut -d' ' -f2-
}

# Function to process files in batches with rate limiting
process_with_rate_limiting() {
    local files=("$@")
    local total_files=${#files[@]}
    local processed=0
    local failed=0
    local token_usage=0
    local window_start=$(date +%s)
    local start_time=$(date +%s)
    
    if [ $total_files -eq 0 ]; then
        print_warning "No files to process"
        return 0
    fi
    
    print_info "📊 Processing $total_files files with rate limiting (target: $TOKEN_LIMIT_PER_MIN tokens/min)"
    echo ""
    
    # Create a progress file
    local progress_file="/tmp/graphify_progress_$$.txt"
    
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local current=$((i + 1))
        local percent=$((current * 100 / total_files))
        
        # Estimate tokens for this file
        local est_tokens=$(estimate_tokens "$file")
        local file_size=$(get_file_size "$file")
        local filename=$(basename "$file")
        local dirname=$(dirname "$file")
        
        # Check if we need to wait to stay under limit
        local current_time=$(date +%s)
        local elapsed=$((current_time - window_start))
        
        if [ $elapsed -ge $TOKEN_WINDOW ]; then
            # Reset window
            window_start=$current_time
            token_usage=0
            print_token_info "🔄 Token window reset"
        fi
        
        if [ $((token_usage + est_tokens)) -gt $TOKEN_LIMIT_PER_MIN ]; then
            local wait_time=$((TOKEN_WINDOW - elapsed + 2))  # Add 2 seconds buffer
            if [ $wait_time -gt 0 ]; then
                print_warning "⏳ Token limit approaching ($token_usage/$TOKEN_LIMIT_PER_MIN). Waiting ${wait_time}s..."
                
                # Show a countdown
                for ((w=wait_time; w>0; w--)); do
                    echo -ne "\r${YELLOW}⏳ Waiting $w seconds...${NC}    "
                    sleep 1
                done
                echo ""
                
                # Reset window after waiting
                window_start=$(date +%s)
                token_usage=0
            fi
        fi
        
        # Calculate ETA
        local elapsed_time=$((current_time - start_time))
        local avg_time_per_file=0
        if [ $i -gt 0 ]; then
            avg_time_per_file=$((elapsed_time / i))
            local remaining=$(( (total_files - current) * avg_time_per_file ))
            local eta_min=$((remaining / 60))
            local eta_sec=$((remaining % 60))
            local eta_str="${eta_min}m${eta_sec}s"
        else
            local eta_str="calculating..."
        fi
        
        # Print progress
        echo ""
        print_progress "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_progress "📁 [$current/$total_files] $percent% complete"
        print_progress "📄 File: $filename"
        print_progress "📂 Path: $dirname"
        print_progress "📏 Size: $file_size | Estimated tokens: $est_tokens"
        print_progress "⏱️  ETA: $eta_str | Elapsed: ${elapsed_time}s"
        print_progress "💰 Token usage this window: $token_usage/$TOKEN_LIMIT_PER_MIN"
        echo ""
        
        # Process the file
        print_info "🔄 Processing: $filename"
        
        # Run graphify and capture output
        if graphify extract "$file" --backend gemini --incremental 2>&1 | tee -a "/tmp/graphify_log_$$.txt"; then
            processed=$((processed + 1))
            token_usage=$((token_usage + est_tokens))
            print_info "✅ Successfully processed: $filename"
        else
            failed=$((failed + 1))
            print_error "❌ Failed to process: $filename"
            # Wait on error to avoid hammering the API
            sleep 10
        fi
        
        # Show summary after each file
        echo ""
        print_progress "📊 Progress: $processed processed, $failed failed, $((total_files - current)) remaining"
        print_token_info "💰 Total token usage: $token_usage/$TOKEN_LIMIT_PER_MIN (${token_usage} used this window)"
        
        # Small delay between files regardless
        if [ $i -lt $((total_files - 1)) ]; then
            sleep 1
        fi
    done
    
    # Final summary
    local total_time=$(( $(date +%s) - start_time ))
    local total_min=$((total_time / 60))
    local total_sec=$((total_time % 60))
    
    echo ""
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "✅ Processing complete!"
    print_info "📊 Final Summary:"
    print_info "   📁 Total files: $total_files"
    print_info "   ✅ Processed: $processed"
    print_info "   ❌ Failed: $failed"
    print_info "   ⏱️  Time: ${total_min}m${total_sec}s"
    print_info "   💰 Total tokens used: $token_usage"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Clean up temp files
    rm -f "/tmp/graphify_progress_$$.txt"
    
    return $failed
}

# Function to process specific folders with rate limiting
process_folders_with_limiting() {
    local folders=("$@")
    local all_files=()
    
    print_info "📂 Collecting files from ${#folders[@]} folders..."
    echo ""
    
    for folder in "${folders[@]}"; do
        if [ -d "$folder" ]; then
            print_info "🔍 Scanning: $folder"
            local file_count=0
            while IFS= read -r file; do
                all_files+=("$file")
                file_count=$((file_count + 1))
            done < <(get_files_sorted_by_size "$folder")
            print_info "   Found $file_count files in $folder"
        else
            print_warning "⚠️  Folder not found: $folder"
        fi
    done
    
    local total_files=${#all_files[@]}
    print_info ""
    print_info "📊 Total files found: $total_files"
    
    if [ $total_files -eq 0 ]; then
        print_warning "No files found to process"
        return 0
    fi
    
    # Show file size distribution
    print_info "📊 File size distribution:"
    local small=0 medium=0 large=0
    for file in "${all_files[@]}"; do
        local size=$(wc -c < "$file" 2>/dev/null || echo 0)
        if [ $size -lt 10240 ]; then  # < 10KB
            small=$((small + 1))
        elif [ $size -lt 102400 ]; then  # < 100KB
            medium=$((medium + 1))
        else
            large=$((large + 1))
        fi
    done
    print_info "   📄 Small (<10KB): $small files"
    print_info "   📄 Medium (10-100KB): $medium files"
    print_info "   📄 Large (>100KB): $large files"
    echo ""
    
    # Ask for confirmation before starting
    read -p "Continue with processing? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        return 0
    fi
    
    # Process all files with rate limiting
    process_with_rate_limiting "${all_files[@]}"
}

# Check if graphify is installed
if ! command -v graphify &> /dev/null
then
    print_info "graphify could not be found, installing..."
    pip install graphify
    if [ $? -ne 0 ]; then
        print_error "Failed to install graphify. Please install manually."
        exit 1
    fi
fi

# Check if graph already exists
if [ -f "$GRAPHIFY_OUTPUT/graph.json" ]; then
    print_info "Existing knowledge graph found in $GRAPHIFY_OUTPUT/"
    
    # Get file sizes for comparison
    GRAPH_SIZE=$(du -h "$GRAPHIFY_OUTPUT/graph.json" | cut -f1)
    CACHE_SIZE=$(du -h "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
    
    print_info "Current graph size: $GRAPH_SIZE"
    print_info "Cache size: $CACHE_SIZE"
    
    # Ask user what to do
    echo ""
    echo "What would you like to do?"
    echo "1) Process specific folders (bit by bit - recommended for rate limiting)"
    echo "2) Process by file type (start with smallest files) ⭐ RECOMMENDED"
    echo "3) Process by file size (smallest first)"
    echo "4) Rebuild graph from scratch (full rebuild - uses most tokens)"
    echo "5) Update graph incrementally (watch mode - uses fewest tokens)"
    echo "6) Query the existing graph (zero token cost)"
    echo "7) Exit"
    read -p "Choose option (1-7): " choice
    
    case $choice in
        1)
            print_info "Process specific folders bit by bit..."
            echo ""
            echo "Enter folder paths to process (space-separated) or 'all' for all folders:"
            echo "Example: src/models src/services src/controllers"
            read -p "Folders: " folder_input
            
            if [ "$folder_input" = "all" ]; then
                # Process all top-level folders
                folders=()
                for dir in */; do
                    if [ -d "$dir" ] && [ "$dir" != "node_modules/" ] && [ "$dir" != ".git/" ] && [ "$dir" != "$GRAPHIFY_OUTPUT/" ]; then
                        if ! is_ignored "$dir"; then
                            folders+=("${dir%/}")
                        fi
                    fi
                done
                process_folders_with_limiting "${folders[@]}"
            else
                IFS=' ' read -ra folders <<< "$folder_input"
                process_folders_with_limiting "${folders[@]}"
            fi
            ;;
        2)
            print_info "📊 Processing by file type (smallest files first)..."
            print_info "✅ This is the most token-efficient approach"
            echo ""
            
            # Find all files and process smallest first
            print_info "🔍 Scanning project directory for files..."
            all_files=()
            while IFS= read -r file; do
                all_files+=("$file")
            done < <(get_files_sorted_by_size "$PROJECT_DIR")
            
            total_files=${#all_files[@]}
            print_info "📊 Found $total_files files in total"
            echo ""
            
            if [ $total_files -eq 0 ]; then
                print_warning "No files found to process"
                exit 0
            fi
            
            # Show top 10 smallest files as preview
            print_info "📋 Preview: 10 smallest files"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for i in {0..9}; do
                if [ $i -lt $total_files ]; then
                    file="${all_files[$i]}"
                    size=$(get_file_size "$file")
                    filename=$(basename "$file")
                    tokens=$(estimate_tokens "$file")
                    printf "  %2d. %-40s %8s  ~%5d tokens\n" $((i+1)) "$filename" "$size" "$tokens"
                fi
            done
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            
            # Ask user how many files to process
            echo "How many files would you like to process in this session?"
            echo "  ⚡ Recommended: 10-50 files per session (to stay under rate limits)"
            echo "  📊 Total available: $total_files files"
            echo "  💡 Enter 'all' to process all files (may take multiple sessions)"
            echo "  💡 Enter a number to process that many smallest files"
            read -p "Number of files: " file_count
            
            if [ "$file_count" = "all" ]; then
                print_info "📊 Processing all $total_files files..."
                process_with_rate_limiting "${all_files[@]}"
            elif [[ "$file_count" =~ ^[0-9]+$ ]] && [ "$file_count" -gt 0 ]; then
                if [ "$file_count" -gt "$total_files" ]; then
                    print_warning "Requested $file_count files but only $total_files available"
                    file_count=$total_files
                fi
                selected_files=("${all_files[@]:0:$file_count}")
                print_info "📊 Processing first $file_count files (smallest first)"
                echo ""
                
                # Show which files will be processed
                print_info "📋 Files to process in this session:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                for i in "${!selected_files[@]}"; do
                    file="${selected_files[$i]}"
                    size=$(get_file_size "$file")
                    filename=$(basename "$file")
                    tokens=$(estimate_tokens "$file")
                    printf "  %2d. %-40s %8s  ~%5d tokens\n" $((i+1)) "$filename" "$size" "$tokens"
                done
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                
                read -p "Continue with processing? (y/n): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    process_with_rate_limiting "${selected_files[@]}"
                    
                    # After processing, ask if user wants to continue with next batch
                    if [ $file_count -lt $total_files ]; then
                        echo ""
                        read -p "Process next batch of $file_count files? (y/n): " -n 1 -r
                        echo ""
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            remaining_files=("${all_files[@]:$file_count}")
                            selected_files=("${remaining_files[@]:0:$file_count}")
                            process_with_rate_limiting "${selected_files[@]}"
                        fi
                    fi
                else
                    print_info "Cancelled"
                    exit 0
                fi
            else
                print_error "Invalid input. Please enter a number or 'all'"
                exit 1
            fi
            ;;
        3)
            print_info "Processing by file size (smallest first)..."
            print_info "This approach uses fewer tokens per file"
            
            # Offer size-based filtering
            echo ""
            echo "Select size threshold (files smaller than this):"
            echo "1) 100KB (very small files)"
            echo "2) 500KB (small files)"
            echo "3) 1MB (medium files)"
            echo "4) 5MB (large files)"
            echo "5) No limit (all files)"
            read -p "Choose (1-5): " size_choice
            
            case $size_choice in
                1) max_size=$((100 * 1024)) ;;
                2) max_size=$((500 * 1024)) ;;
                3) max_size=$((1 * 1024 * 1024)) ;;
                4) max_size=$((5 * 1024 * 1024)) ;;
                *) max_size=0 ;;
            esac
            
            # Find files by size
            print_info "🔍 Scanning for files matching size criteria..."
            all_files=()
            while IFS= read -r file; do
                if [ $max_size -eq 0 ] || [ $(wc -c < "$file" 2>/dev/null || echo 0) -le $max_size ]; then
                    all_files+=("$file")
                fi
            done < <(get_files_sorted_by_size "$PROJECT_DIR")
            
            total_files=${#all_files[@]}
            print_info "📊 Found $total_files files matching criteria"
            
            if [ $total_files -gt 0 ]; then
                # Ask how many to process
                echo ""
                echo "How many of these $total_files files would you like to process?"
                echo "Enter a number or 'all' for all files:"
                read -p "Number: " file_count
                
                if [ "$file_count" = "all" ]; then
                    process_with_rate_limiting "${all_files[@]}"
                elif [[ "$file_count" =~ ^[0-9]+$ ]] && [ "$file_count" -gt 0 ]; then
                    if [ "$file_count" -gt "$total_files" ]; then
                        file_count=$total_files
                    fi
                    selected_files=("${all_files[@]:0:$file_count}")
                    process_with_rate_limiting "${selected_files[@]}"
                else
                    print_error "Invalid input"
                    exit 1
                fi
            else
                print_warning "No files found matching criteria"
            fi
            ;;
        4)
            print_info "Rebuilding graph from scratch..."
            print_warning "This will consume the most tokens for the entire codebase"
            print_info "Consider using options 1-3 for incremental building instead"
            read -p "Are you sure? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                graphify extract "$PROJECT_DIR" --backend gemini --force
            else
                print_info "Cancelled"
                exit 0
            fi
            ;;
        5)
            print_info "Starting watch mode for incremental updates..."
            print_info "Graphify will only process changed files (saves tokens)"
            graphify extract "$PROJECT_DIR" --backend gemini --watch
            ;;
        6)
            print_info "Querying existing graph..."
            print_info "You can now ask questions about your codebase:"
            echo ""
            echo "Example queries:"
            echo "  - 'Show me all functions that call process_payment'"
            echo "  - 'What are the dependencies of module X?'"
            echo "  - 'List all API endpoints in this project'"
            echo ""
            echo "To query: graphify query \"your question here\""
            echo "Or check: cat $GRAPHIFY_OUTPUT/GRAPH_REPORT.md"
            echo "Or open: $GRAPHIFY_OUTPUT/graph.html in your browser"
            exit 0
            ;;
        7)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    print_info "No existing graph found. Building for the first time..."
    print_info "This will consume tokens to build the initial knowledge graph"
    print_info "But ALL future queries will be nearly free!"
    echo ""
    echo "What approach would you like to use?"
    echo "1) Smart build - process by file size (recommended - saves tokens)"
    echo "2) Full build - process everything at once (uses more tokens)"
    read -p "Choose (1-2): " build_choice
    
    case $build_choice in
        1)
            print_info "Starting smart build..."
            print_info "Files will be processed in order of size (smallest first)"
            
            all_files=()
            while IFS= read -r file; do
                all_files+=("$file")
            done < <(get_files_sorted_by_size "$PROJECT_DIR")
            
            total_files=${#all_files[@]}
            print_info "Found $total_files files to process"
            
            if [ $total_files -eq 0 ]; then
                print_warning "No files found to process"
                exit 0
            fi
            
            # Show file size distribution
            print_info "File size distribution:"
            small=0 medium=0 large=0
            for file in "${all_files[@]}"; do
                size=$(wc -c < "$file" 2>/dev/null || echo 0)
                if [ $size -lt 10240 ]; then
                    small=$((small + 1))
                elif [ $size -lt 102400 ]; then
                    medium=$((medium + 1))
                else
                    large=$((large + 1))
                fi
            done
            print_info "   Small (<10KB): $small files"
            print_info "   Medium (10-100KB): $medium files"
            print_info "   Large (>100KB): $large files"
            echo ""
            
            echo "How many files would you like to process? (Recommended: 10-50)"
            echo "Enter a number or 'all' for all files:"
            read -p "Number: " file_count
            
            if [ "$file_count" = "all" ]; then
                process_with_rate_limiting "${all_files[@]}"
            elif [[ "$file_count" =~ ^[0-9]+$ ]] && [ "$file_count" -gt 0 ]; then
                if [ "$file_count" -gt "$total_files" ]; then
                    file_count=$total_files
                fi
                selected_files=("${all_files[@]:0:$file_count}")
                print_info "Processing first $file_count files (smallest first)"
                process_with_rate_limiting "${selected_files[@]}"
            else
                print_error "Invalid input"
                exit 1
            fi
            ;;
        2)
            graphify extract "$PROJECT_DIR" --backend gemini
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Check if build was successful
if [ $? -eq 0 ] && [ -f "$GRAPHIFY_OUTPUT/graph.json" ]; then
    print_info "✅ Knowledge graph built successfully!"
    print_info ""
    print_info "📊 Token Savings Tips:"
    print_info "1. Use watch mode for incremental updates: graphify extract . --backend gemini --watch"
    print_info "2. Query the graph instead of pasting code: graphify query 'your question'"
    print_info "3. Share graph.json with AI assistants instead of source files"
    print_info "4. Open graph.html for visual exploration"
    print_info ""
    print_info "📁 Output files:"
    print_info "  - $GRAPHIFY_OUTPUT/graph.json (persistent knowledge graph)"
    print_info "  - $GRAPHIFY_OUTPUT/GRAPH_REPORT.md (human-readable report)"
    print_info "  - $GRAPHIFY_OUTPUT/graph.html (interactive visualization)"
    print_info "  - $GRAPHIFY_OUTPUT/cache/ (incremental update cache)"
    
    # Create a helper alias/function for easy querying
    echo ""
    print_info "Adding query helper function to your shell session..."
    alias graphify-query='graphify query'
    echo "Now you can run: graphify-query \"your question\""
    
    # Show a sample of the graph
    if command -v jq &> /dev/null; then
        NODE_COUNT=$(jq '.nodes | length' "$GRAPHIFY_OUTPUT/graph.json" 2>/dev/null || echo "unknown")
        EDGE_COUNT=$(jq '.edges | length' "$GRAPHIFY_OUTPUT/graph.json" 2>/dev/null || echo "unknown")
        print_info "Graph stats: $NODE_COUNT nodes, $EDGE_COUNT edges"
    fi
else
    print_error "Failed to build knowledge graph"
    exit 1
fi

# ============================================
# ANTIGRAVITY INTEGRATION
# ============================================
print_step "Setting up Antigravity integration..."

# Run the official install command
print_info "Running: graphify antigravity install"
graphify antigravity install

# Check if the install succeeded
if [ $? -eq 0 ]; then
    print_info "✅ Antigravity integration installed successfully!"
    
    # Check where the files were installed
    if [ -f ".agents/workflows/graphify.md" ]; then
        print_info "📁 Files installed to: .agents/"
        AGENT_DIR=".agents"
    elif [ -f ".agent/workflows/graphify.md" ]; then
        print_info "📁 Files installed to: .agent/"
        AGENT_DIR=".agent"
    else
        print_warning "Could not find installed files"
        AGENT_DIR=""
    fi
    
    # Fix: Create symlink from .agents to .agent if needed
    if [ "$AGENT_DIR" == ".agents" ]; then
        print_info "Creating symlink: .agent -> .agents (for Antigravity compatibility)"
        if [ -L ".agent" ]; then
            rm .agent
        elif [ -d ".agent" ]; then
            print_warning ".agent directory already exists. Moving it to .agent.backup"
            mv .agent .agent.backup
        fi
        ln -s .agents .agent
        print_info "✅ Symlink created: .agent -> .agents"
    fi
else
    print_warning "graphify antigravity install command failed"
    print_info "Creating manual Antigravity integration files..."
    
    # Create both directories to be safe
    mkdir -p .agent/rules .agent/workflows
    mkdir -p .agents/rules .agents/workflows
    
    # Create rule file for both locations
    for AGENT_DIR in .agent .agents; do
        cat > "$AGENT_DIR/rules/graphify.md" << 'EOF'
---
type: rule
description: Always use Graphify knowledge graph before searching code
---

# Graphify Knowledge Graph

## Always Use Graphify First

When answering questions about this codebase:

1. **PRIORITY**: First check if the answer exists in `graphify-out/GRAPH_REPORT.md`
2. **NEXT**: Query `graphify-out/graph.json` for structural questions
3. **LAST**: Only read raw source files when:
   - The graph doesn't contain the information
   - You need to see exact implementation details
   - You're planning to edit code

## What Graphify Can Tell You

- **Function calls**: Who calls what
- **Dependencies**: What modules depend on each other
- **Relationships**: How different parts of the code connect
- **Architecture**: Overall structure of the project

## Common Queries

- "What calls function X?"
- "What are the dependencies of module Y?"
- "Show me all API endpoints"
- "How does authentication work?"
- "What database models exist?"

## Available Files

- `graphify-out/graph.json` - Complete knowledge graph
- `graphify-out/GRAPH_REPORT.md` - Human-readable summary
- `graphify-out/graph.html` - Interactive visualization
EOF

        # Create workflow file for both locations
        cat > "$AGENT_DIR/workflows/graphify.md" << 'EOF'
---
type: workflow
description: Query your codebase using the Graphify knowledge graph
---

# /graphify - Query the codebase knowledge graph

## Description
Use this command to ask questions about the codebase structure using Graphify.

## Usage
`/graphify [your question]`

## Examples
- `/graphify What functions call process_payment?`
- `/graphify Show me all API endpoints in this project`
- `/graphify How does authentication work?`
- `/graphify What are the dependencies of the auth module?`

## Workflow
1. Read `graphify-out/graph.json` to answer structural questions
2. Read `graphify-out/GRAPH_REPORT.md` for high-level understanding
3. Only read source files if the graph doesn't have the answer

## Benefits
- Saves tokens (95-99% reduction per query)
- Faster answers (instant graph queries vs file search)
- More accurate (shows actual relationships, not just text matches)
EOF
    done
    
    # Create symlink if needed
    if [ -L ".agent" ]; then
        rm .agent
    elif [ -d ".agent" ] && [ -d ".agents" ]; then
        print_warning "Both .agent and .agents exist. Keeping .agent"
    elif [ -d ".agents" ] && [ ! -d ".agent" ]; then
        ln -s .agents .agent
        print_info "✅ Created symlink: .agent -> .agents"
    fi
    
    print_info "✅ Manual Antigravity files created in both .agent/ and .agents/"
fi

# ============================================
# SETUP MCP CONFIGURATION (Optional)
# ============================================
print_step "Setting up MCP configuration for advanced navigation..."

MCP_CONFIG_DIR="$HOME/.gemini/antigravity"
MCP_CONFIG_FILE="$MCP_CONFIG_DIR/mcp_config.json"

if [ ! -f "$MCP_CONFIG_FILE" ]; then
    print_info "Creating MCP configuration for Graphify..."
    mkdir -p "$MCP_CONFIG_DIR"
    
    cat > "$MCP_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "graphify": {
      "command": "uv",
      "args": ["run", "--with", "graphifyy", "--with", "mcp", "-m", "graphify.serve", "$(pwd)/graphify-out/graph.json"]
    }
  }
}
EOF
    print_info "✅ MCP config created at: $MCP_CONFIG_FILE"
else
    # Check if graphify is already in the config
    if ! grep -q "graphify" "$MCP_CONFIG_FILE"; then
        print_info "Adding graphify to existing MCP config..."
        # Use jq if available, otherwise manual backup
        if command -v jq &> /dev/null; then
            # Backup the original
            cp "$MCP_CONFIG_FILE" "$MCP_CONFIG_FILE.backup"
            # Add graphify to mcpServers
            jq '.mcpServers += {"graphify": {"command": "uv", "args": ["run", "--with", "graphifyy", "--with", "mcp", "-m", "graphify.serve", "'$(pwd)'/graphify-out/graph.json"]}}' "$MCP_CONFIG_FILE" > "$MCP_CONFIG_FILE.tmp"
            mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"
            print_info "✅ Graphify added to MCP config"
        else
            print_warning "jq not installed. Skipping MCP config update."
            print_info "To add manually, add this to $MCP_CONFIG_FILE:"
            echo '  "graphify": {'
            echo '    "command": "uv",'
            echo '    "args": ["run", "--with", "graphifyy", "--with", "mcp", "-m", "graphify.serve", "'$(pwd)'/graphify-out/graph.json"]'
            echo '  }'
        fi
    else
        print_info "✅ Graphify already configured in MCP"
    fi
fi

# ============================================
# CREATE HELPER SCRIPTS
# ============================================
print_step "Creating helper scripts..."

# Create query-graphify.sh if it doesn't exist
if [ ! -f "query-graphify.sh" ]; then
    cat > "query-graphify.sh" << 'EOF'
#!/bin/bash
# query-graphify.sh - Quick graph queries and token savings tracker

GRAPH_FILE="graphify-out/graph.json"

if [ ! -f "$GRAPH_FILE" ]; then
    echo "❌ No graph found. Run setup first!"
    exit 1
fi

# If argument is --stats, -s, or no arguments are provided, show stats and usage
if [ $# -eq 0 ] || [ "$1" = "--stats" ] || [ "$1" = "-s" ]; then
    # Estimate graph size
    if command -v numfmt &> /dev/null; then
        GRAPH_SIZE=$(wc -c < "$GRAPH_FILE" | numfmt --to=si)
    else
        GRAPH_SIZE=$(wc -c < "$GRAPH_FILE")
    fi

    echo "📊 Graph size: $GRAPH_SIZE"
    echo "💡 Each query costs ~200-500 tokens vs thousands with full files"
    echo "Estimated savings per query: 95-99%"
    echo ""
    echo "Usage: ./query-graphify.sh 'your question'"
    echo "       ./query-graphify.sh --stats (or -s) to view this info again"
    echo ""
    echo "Examples:"
    echo "  ./query-graphify.sh 'Show all API endpoints'"
    echo "  ./query-graphify.sh 'What depends on module X?'"
    echo "  ./query-graphify.sh 'List all database models'"
    echo ""
    echo "To maximize savings:"
    echo "  1. Keep watch mode running: graphify extract . --backend gemini --watch"
    echo "  2. Query the graph using this script or 'graphify query'"
    echo "  3. Never paste entire files again!"
    
    if [ $# -eq 0 ]; then
        exit 1
    else
        exit 0
    fi
fi

graphify query "$1"
EOF
    chmod +x query-graphify.sh
    print_info "✅ Created query-graphify.sh (combined query helper & token tracker)"
fi

# ============================================
# OPTIONAL: Start watch mode
# ============================================
echo ""
read -p "Start watch mode for automatic incremental updates? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Starting watch mode in background..."
    graphify extract "$PROJECT_DIR" --backend gemini --watch &
    WATCH_PID=$!
    print_info "Watch mode running with PID: $WATCH_PID"
    print_info "To stop: kill $WATCH_PID"
fi

# ============================================
# FINAL SUMMARY
# ============================================
print_info "✨ Setup complete! You're now ready to save tokens with Graphify."
echo ""
print_info "📋 Next steps:"
echo "  1. COMPLETELY RESTART Antigravity (close and reopen)"
echo "  2. Type '/' in the chat - you should see '/graphify'"
echo "  3. Type: /graphify What does this codebase do?"
echo "  4. Watch the agent use the graph instead of grepping files!"
echo ""
print_info "📊 Expected token savings: 95-99% per query"
echo ""
print_info "🔧 Quick commands:"
echo "  graphify query 'your question'  - Query from terminal"
echo "  ./query-graphify.sh 'question'  - Use the helper script to query graph"
echo "  ./query-graphify.sh --stats    - View potential savings and stats"
echo ""
print_info "📁 Integration files installed:"
if [ -d ".agents" ]; then
    echo "  - .agents/rules/graphify.md"
    echo "  - .agents/workflows/graphify.md"
fi
if [ -d ".agent" ]; then
    if [ -L ".agent" ]; then
        echo "  - .agent -> .agents (symlink)"
    else
        echo "  - .agent/rules/graphify.md"
        echo "  - .agent/workflows/graphify.md"
    fi
fi
if [ -f "$MCP_CONFIG_FILE" ]; then
    echo "  - $MCP_CONFIG_FILE (MCP config)"
fi