#!/bin/bash

# ACS.jl Documentation Build Script
# This script builds the documentation locally

echo "Building ACS.jl documentation..."

# Navigate to docs directory
cd "$(dirname "$0")"

# Activate docs environment and build
julia --project=. -e "
using Pkg
Pkg.instantiate()
include(\"make.jl\")
"

# Check if build was successful
if [ -d "build" ]; then
    echo "✅ Documentation built successfully!"
    echo "📁 Output directory: $(pwd)/build"
    echo "🌐 Open $(pwd)/build/index.html in your browser to view the documentation"
    
    # Optionally open the documentation in the default browser (macOS)
    if command -v open &> /dev/null; then
        echo "🚀 Opening documentation in browser..."
        open build/index.html
    fi
else
    echo "❌ Documentation build failed!"
    exit 1
fi
