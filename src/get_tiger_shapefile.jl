"""
    get_tiger_shapefile(year::Int, geography::String)

Download a TIGER/Line shapefile from the US Census Bureau FTP server.

# Arguments
- `year::Int`: The year of the shapefile to download (e.g., 2023)
- `geography::String`: The geographic level, must be either "state" or "county"

# Returns
- `Bool`: `true` if download was successful, `false` otherwise

# Examples
```julia
# Download 2023 state boundaries
success = get_tiger_shapefile(2023, "county")

# Download 2023 county boundaries  
success = get_tiger_shapefile(2023, "county")
```

# Notes
- Downloads 500k resolution shapefiles from ftp2.census.gov
- Files are saved as ZIP archives in the current working directory
- Existing files with the same name will be overwritten
"""
function get_tiger_shapefile(year::Int, geography::String)
    # Validate geography argument
    if !(geography in ["state", "county"])
        error("geography must be either \"state\" or \"county\", got \"$geography\"")
    end
    
    # URL for the shapefile via FTP
    url = "ftp://ftp2.census.gov/geo/tiger/GENZ$year/shp/cb_$year" * "_us_$geography" * "_500k.zip"
    output_path = "cb_$year" * "_us_$geography" * "_500k.zip"
        
    try
        # Remove existing file if present
        if isfile(output_path)
            println("Removing existing file...")
            rm(output_path)
        end
        
        # Download the file using curl
        println("Starting download from FTP...")
        cmd = `curl -s -o $output_path $url`
        println("Running: $cmd")
        run(cmd)
        
        # Check if file exists and its size
        if isfile(output_path)
            filesize_mb = round(filesize(output_path) / (1024 * 1024), digits=2)
            println("Download successful! File size: $filesize_mb MB")
            return true
        else
            println("Error: File not found after download")
            return false
        end
    catch e
        println("Error during download: $e")
        return false
    end
end

export get_tiger_shapefile