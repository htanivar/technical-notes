#!/bin/bash
# query-graphify.sh - Quick graph queries with markdown report generation

GRAPH_FILE="graphify-out/graph.json"
REPORT_BASE_DIR="local/graphify"

if [ ! -f "$GRAPH_FILE" ]; then
    echo "❌ No graph found. Run setup first!"
    exit 1
fi

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to format and beautify the graph query response
format_response() {
    local response="$1"
    
    # If response is empty or just whitespace
    if [[ -z "${response// }" ]]; then
        echo -e "${RED}❌ No results found for your query${NC}"
        return
    fi
    
    # Check if it's a BFS traversal output (contains "Traversal:" and "NODE" lines)
    if echo "$response" | grep -q "Traversal:" && echo "$response" | grep -q "NODE"; then
        format_bfs_output "$response"
        return
    fi
    
    # Check if it's a simple node/edge list
    if echo "$response" | grep -q "NODE" || echo "$response" | grep -q "EDGE"; then
        format_node_edge_output "$response"
        return
    fi
    
    # Default: show as is but with some formatting
    echo -e "${CYAN}${BOLD}📊 Query Results:${NC}"
    echo "$response" | sed 's/NODE /🔹 /g' | sed 's/EDGE /➡️ /g'
}

# Function to format BFS output for terminal
format_bfs_output() {
    local response="$1"
    
    # Extract traversal info
    local traversal_info=$(echo "$response" | grep "Traversal:" | head -1)
    local start_nodes=$(echo "$traversal_info" | grep -o "Start: \[[^\]]*\]" | sed 's/Start: \[//' | sed 's/\]//')
    local total_nodes=$(echo "$traversal_info" | grep -o "[0-9]* nodes found" | grep -o "[0-9]*")
    
    echo -e "${BOLD}${BLUE}📊 Graph Traversal Report${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🔍 ${BOLD}Search Query:${NC} $start_nodes"
    echo -e "📌 ${BOLD}Total Nodes Found:${NC} $total_nodes"
    echo -e "📁 ${BOLD}File Locations:${NC} $(echo "$response" | grep -o "src=[^ ]*" | sort -u | wc -l | tr -d ' ') unique files"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Extract and group nodes by file
    echo -e "${BOLD}${GREEN}📂 Nodes by File:${NC}"
    echo "$response" | grep "NODE" | while read -r node_line; do
        # Extract node name and location
        node_name=$(echo "$node_line" | grep -o "NODE [^[]*" | sed 's/NODE //' | sed 's/ $//')
        src=$(echo "$node_line" | grep -o "src=[^ ]*" | sed 's/src=//')
        community=$(echo "$node_line" | grep -o "community=[0-9]*" | sed 's/community=//')
        
        # Determine emoji based on node type
        emoji="🔹"
        if echo "$node_name" | grep -q "()"; then
            emoji="⚡"  # Function
        elif echo "$node_name" | grep -q "\.[a-z]*$"; then
            emoji="📄"  # File
        elif echo "$node_name" | grep -q "^[A-Z]"; then
            emoji="📦"  # Class/Type
        else
            emoji="🔸"  # Other
        fi
        
        # Color based on community (group) if available
        if [ ! -z "$community" ]; then
            color=$CYAN
            community_tag=" [group: $community]"
        else
            color=$NC
            community_tag=""
        fi
        
        echo -e "  ${color}${emoji}${NC} ${BOLD}$node_name${NC} ${color}($src)${NC}${community_tag}"
    done | sort -k2
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔗 Relationship Summary:${NC}"
    
    # Group edges by type
    echo "$response" | grep "EDGE" | while read -r edge_line; do
        # Extract source, type, target
        source=$(echo "$edge_line" | grep -o "EDGE [^ ]*" | sed 's/EDGE //')
        edge_type=$(echo "$edge_line" | grep -o "--[a-z_]*" | head -1 | sed 's/--//')
        
        # Clean up target
        if echo "$edge_line" | grep -q "-->"; then
            target=$(echo "$edge_line" | sed 's/.*--> //' | cut -d' ' -f1)
        else
            target="unknown"
        fi
        
        # Get context if available
        context=""
        if echo "$edge_line" | grep -q "context="; then
            context=$(echo "$edge_line" | grep -o "context=[^]]*" | sed 's/context=//' | sed 's/ $//')
            context=" (${context})"
        fi
        
        # Determine edge type emoji
        edge_emoji="→"
        case "$edge_type" in
            "calls") edge_emoji="📞" ;;
            "contains") edge_emoji="📂" ;;
            "imports") edge_emoji="📥" ;;
            "imports_from") edge_emoji="📤" ;;
            "extends") edge_emoji="🔗" ;;
            "implements") edge_emoji="⚙️" ;;
            *) edge_emoji="➡️" ;;
        esac
        
        # Color based on edge type
        color=$NC
        case "$edge_type" in
            "calls") color=$GREEN ;;
            "contains") color=$BLUE ;;
            "imports"|"imports_from") color=$YELLOW ;;
        esac
        
        echo -e "  ${color}${edge_emoji}${NC} ${BOLD}$source${NC} ${color}→${NC} ${BOLD}$target${NC} ${color}[$edge_type]${NC}${context}"
    done | sort -k4
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Add insights
    echo -e "${BOLD}${PURPLE}💡 Insights:${NC}"
    
    # Count different types of relationships
    calls_count=$(echo "$response" | grep -c "EDGE .*--calls")
    imports_count=$(echo "$response" | grep -c "EDGE .*--imports")
    contains_count=$(echo "$response" | grep -c "EDGE .*--contains")
    
    if [ $calls_count -gt 0 ]; then
        echo -e "  📞 ${calls_count} function call(s) detected"
    fi
    if [ $imports_count -gt 0 ]; then
        echo -e "  📥 ${imports_count} import relationship(s)"
    fi
    if [ $contains_count -gt 0 ]; then
        echo -e "  📂 ${contains_count} file containment(s)"
    fi
    
    # Check for potential issues
    if echo "$response" | grep -q "INFERRED"; then
        echo -e "  ⚠️  Some relationships were inferred (not explicit in code)"
    fi
    
    echo ""
}

# Function to format node/edge output for terminal
format_node_edge_output() {
    local response="$1"
    
    echo -e "${BOLD}${BLUE}📊 Graph Query Results${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Count nodes and edges
    node_count=$(echo "$response" | grep -c "NODE")
    edge_count=$(echo "$response" | grep -c "EDGE")
    
    echo -e "📌 ${BOLD}Nodes:${NC} $node_count  |  ${BOLD}Edges:${NC} $edge_count"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Extract node names
    if [ $node_count -gt 0 ]; then
        echo -e "\n${BOLD}${GREEN}🔹 Nodes Found:${NC}"
        echo "$response" | grep "NODE" | while read -r node; do
            node_name=$(echo "$node" | grep -o "NODE [^[]*" | sed 's/NODE //' | sed 's/ $//')
            src=$(echo "$node" | grep -o "src=[^ ]*" | sed 's/src=//' | head -1)
            if [ ! -z "$src" ]; then
                echo -e "  • ${BOLD}$node_name${NC} ($src)"
            else
                echo -e "  • ${BOLD}$node_name${NC}"
            fi
        done
    fi
    
    # Extract edges
    if [ $edge_count -gt 0 ]; then
        echo -e "\n${BOLD}${YELLOW}➡️ Relationships:${NC}"
        echo "$response" | grep "EDGE" | while read -r edge; do
            source=$(echo "$edge" | grep -o "EDGE [^ ]*" | sed 's/EDGE //')
            relation=$(echo "$edge" | grep -o "--[a-z_]*" | head -1 | sed 's/--//')
            
            if echo "$edge" | grep -q "-->"; then
                target=$(echo "$edge" | sed 's/.*--> //' | cut -d' ' -f1)
            else
                target="?"
            fi
            
            context=""
            if echo "$edge" | grep -q "context="; then
                context=$(echo "$edge" | grep -o "context=[^]]*" | sed 's/context=//' | sed 's/ $//')
                context=" ($context)"
            fi
            
            echo -e "  • ${BOLD}$source${NC} ${relation} → ${BOLD}$target${NC}${context}"
        done
    fi
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to generate markdown report
generate_markdown_report() {
    local query="$1"
    local response="$2"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local date_dir=$(date +%Y-%m-%d)
    
    # Create safe filename from query
    local safe_query=$(echo "$query" | tr ' ' '_' | tr -cd '[:alnum:]_' | head -c 50)
    local report_dir="$REPORT_BASE_DIR/$date_dir"
    local report_file="$report_dir/${safe_query}_${timestamp}.md"
    
    # Create directory if it doesn't exist
    mkdir -p "$report_dir"
    
    # Start building markdown content
    cat > "$report_file" << EOF
# Graph Query Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Query:** \`$query\`

---

## Summary

EOF
    
    # Extract summary info
    if echo "$response" | grep -q "Traversal:"; then
        local traversal_info=$(echo "$response" | grep "Traversal:" | head -1)
        local start_nodes=$(echo "$traversal_info" | grep -o "Start: \[[^\]]*\]" | sed 's/Start: \[//' | sed 's/\]//')
        local total_nodes=$(echo "$traversal_info" | grep -o "[0-9]* nodes found" | grep -o "[0-9]*")
        
        cat >> "$report_file" << EOF
- **Traversal Type:** BFS (depth=2)
- **Search Start:** \`$start_nodes\`
- **Total Nodes Found:** $total_nodes
- **Unique Files:** $(echo "$response" | grep -o "src=[^ ]*" | sort -u | wc -l | tr -d ' ') files

---

## Nodes by File

EOF
        
        # Add nodes grouped by file
        echo "$response" | grep "NODE" | while read -r node_line; do
            node_name=$(echo "$node_line" | grep -o "NODE [^[]*" | sed 's/NODE //' | sed 's/ $//')
            src=$(echo "$node_line" | grep -o "src=[^ ]*" | sed 's/src=//')
            community=$(echo "$node_line" | grep -o "community=[0-9]*" | sed 's/community=//')
            
            # Determine emoji based on node type
            emoji="🔹"
            if echo "$node_name" | grep -q "()"; then
                emoji="⚡"  # Function
            elif echo "$node_name" | grep -q "\.[a-z]*$"; then
                emoji="📄"  # File
            elif echo "$node_name" | grep -q "^[A-Z]"; then
                emoji="📦"  # Class/Type
            else
                emoji="🔸"  # Other
            fi
            
            community_tag=""
            if [ ! -z "$community" ]; then
                community_tag=" *(group: $community)*"
            fi
            
            echo "- $emoji **\`$node_name\`** ($src)$community_tag" >> "$report_file"
        done | sort -k2
        
        cat >> "$report_file" << EOF

---

## Relationships

EOF
        
        # Add relationships
        echo "$response" | grep "EDGE" | while read -r edge_line; do
            source=$(echo "$edge_line" | grep -o "EDGE [^ ]*" | sed 's/EDGE //')
            edge_type=$(echo "$edge_line" | grep -o "--[a-z_]*" | head -1 | sed 's/--//')
            
            if echo "$edge_line" | grep -q "-->"; then
                target=$(echo "$edge_line" | sed 's/.*--> //' | cut -d' ' -f1)
            else
                target="unknown"
            fi
            
            context=""
            if echo "$edge_line" | grep -q "context="; then
                context=$(echo "$edge_line" | grep -o "context=[^]]*" | sed 's/context=//' | sed 's/ $//')
                context=" *($context)*"
            fi
            
            # Determine edge type emoji
            edge_emoji="→"
            case "$edge_type" in
                "calls") edge_emoji="📞" ;;
                "contains") edge_emoji="📂" ;;
                "imports") edge_emoji="📥" ;;
                "imports_from") edge_emoji="📤" ;;
                "extends") edge_emoji="🔗" ;;
                "implements") edge_emoji="⚙️" ;;
            esac
            
            echo "- $edge_emoji **\`$source\`** → **\`$target\`** *[$edge_type]*$context" >> "$report_file"
        done | sort -k4
        
        cat >> "$report_file" << EOF

---

## Insights

EOF
        
        # Add insights
        calls_count=$(echo "$response" | grep -c "EDGE .*--calls")
        imports_count=$(echo "$response" | grep -c "EDGE .*--imports")
        contains_count=$(echo "$response" | grep -c "EDGE .*--contains")
        
        if [ $calls_count -gt 0 ]; then
            echo "- 📞 **$calls_count** function call(s) detected" >> "$report_file"
        fi
        if [ $imports_count -gt 0 ]; then
            echo "- 📥 **$imports_count** import relationship(s)" >> "$report_file"
        fi
        if [ $contains_count -gt 0 ]; then
            echo "- 📂 **$contains_count** file containment(s)" >> "$report_file"
        fi
        
        if echo "$response" | grep -q "INFERRED"; then
            echo "- ⚠️ Some relationships were **inferred** (not explicit in code)" >> "$report_file"
        fi
        
    else
        # Simple node/edge output
        node_count=$(echo "$response" | grep -c "NODE")
        edge_count=$(echo "$response" | grep -c "EDGE")
        
        cat >> "$report_file" << EOF
- **Nodes Found:** $node_count
- **Edges Found:** $edge_count

---

## Nodes

EOF
        
        echo "$response" | grep "NODE" | while read -r node; do
            node_name=$(echo "$node" | grep -o "NODE [^[]*" | sed 's/NODE //' | sed 's/ $//')
            src=$(echo "$node" | grep -o "src=[^ ]*" | sed 's/src=//' | head -1)
            if [ ! -z "$src" ]; then
                echo "- **\`$node_name\`** ($src)" >> "$report_file"
            else
                echo "- **\`$node_name\`**" >> "$report_file"
            fi
        done
        
        cat >> "$report_file" << EOF

---

## Relationships

EOF
        
        echo "$response" | grep "EDGE" | while read -r edge; do
            source=$(echo "$edge" | grep -o "EDGE [^ ]*" | sed 's/EDGE //')
            relation=$(echo "$edge" | grep -o "--[a-z_]*" | head -1 | sed 's/--//')
            
            if echo "$edge" | grep -q "-->"; then
                target=$(echo "$edge" | sed 's/.*--> //' | cut -d' ' -f1)
            else
                target="?"
            fi
            
            context=""
            if echo "$edge" | grep -q "context="; then
                context=$(echo "$edge" | grep -o "context=[^]]*" | sed 's/context=//' | sed 's/ $//')
                context=" *($context)*"
            fi
            
            echo "- **\`$source\`** *[$relation]* → **\`$target\`**$context" >> "$report_file"
        done
    fi
    
    # Add footer
    cat >> "$report_file" << EOF

---

*Report generated by query-graphify.sh*
EOF
    
    echo "$report_file"
}

# Main execution
if [ $# -eq 0 ] || [ "$1" = "--stats" ] || [ "$1" = "-s" ]; then
    # Estimate graph size
    if command -v numfmt &> /dev/null; then
        GRAPH_SIZE=$(wc -c < "$GRAPH_FILE" | numfmt --to=si)
    else
        GRAPH_SIZE=$(wc -c < "$GRAPH_FILE")
    fi

    echo -e "${BOLD}${BLUE}📊 Graphify Status${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📁 ${BOLD}Graph Size:${NC} $GRAPH_SIZE"
    echo -e "💡 ${BOLD}Token Savings:${NC} Each query costs ~200-500 tokens vs thousands with full files"
    echo -e "📈 ${BOLD}Estimated savings:${NC} ${GREEN}95-99%${NC} per query"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}./query-graphify.sh${NC} 'your question'     - Query the graph"
    echo -e "  ${CYAN}./query-graphify.sh --stats${NC} (or -s)    - View this info"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${YELLOW}./query-graphify.sh 'Show all API endpoints'${NC}"
    echo -e "  ${YELLOW}./query-graphify.sh 'What depends on module X?'${NC}"
    echo -e "  ${YELLOW}./query-graphify.sh 'List all database models'${NC}"
    echo -e "  ${YELLOW}./query-graphify.sh 'where we use resetPasswordForAll'${NC}"
    echo ""
    echo -e "${BOLD}💡 Tips for maximum savings:${NC}"
    echo -e "  1. Keep watch mode running: ${CYAN}graphify extract . --backend gemini --watch${NC}"
    echo -e "  2. Query the graph using this script or '${CYAN}graphify query${NC}'"
    echo -e "  3. ${GREEN}Never paste entire files again!${NC}"
    echo -e "\n📁 ${BOLD}Reports saved to:${NC} $REPORT_BASE_DIR/YYYY-MM-DD/"
    
    if [ $# -eq 0 ]; then
        exit 1
    else
        exit 0
    fi
fi

# Execute the query and format the output
echo -e "${BOLD}${BLUE}🔍 Querying Graph...${NC}\n"
response=$(graphify query "$1" 2>&1)
formatted_response=$(format_response "$response")

# Display on screen
echo "$formatted_response"

# Generate markdown report
report_file=$(generate_markdown_report "$1" "$response")
echo -e "\n${GREEN}✅ Report saved to: ${BOLD}$report_file${NC}"