using HTTP
using JSON3
using DataFrames
using Dates

"""
    load_variables(year::Int, dataset::String; cache::Bool=false)

This is a port of the tidycensus R package's functions of the same name
https://github.com/walkerke/tidycensus/blob/master/R/helpers.R

Load variables from a decennial Census or American Community Survey dataset.

Finding the right variables to use with Census API can be challenging. 
`load_variables()` attempts to make this easier by fetching and filtering 
variables from the Census website, returning them as a DataFrame.

# Arguments
- `year::Int`: The year for which you are requesting variables (e.g., 2023)
- `dataset::String`: The dataset name as used on the Census website
- `cache::Bool=false`: Whether to cache the dataset for future access (recommended for repeated use)

# Returns
- `DataFrame`: A DataFrame of variables from the requested dataset with columns:
  - `name`: Census variable ID code (e.g., "B01001_001")
  - `label`: Detailed description of the variable
  - `concept`: Information about the table the variable belongs to
  - `geography`: (for 5-year ACS detailed tables) smallest available geography level

# Available Datasets

## American Community Survey (ACS)
- `"acs1"`: 1-year ACS estimates
- `"acs3"`: 3-year ACS estimates (2007-2013 only)
- `"acs5"`: 5-year ACS estimates
- `"acs1/profile"`, `"acs3/profile"`, `"acs5/profile"`: ACS profile tables
- `"acs1/subject"`, `"acs3/subject"`, `"acs5/subject"`: ACS subject tables
- `"acs1/cprofile"`, `"acs5/cprofile"`: ACS comparison profile tables

## Decennial Census
- `"sf1"`, `"sf2"`, `"sf3"`, `"sf4"`: Summary Files
- `"pl"`: Public Law 94-171 Redistricting Data
- `"dhc"`, `"dp"`: Demographic and Housing Characteristics
- Various other decennial datasets (see full list below)

# Examples
```julia
# Load 2023 5-year ACS variables with caching
v23 = load_variables(2023, "acs5", cache=true)

# Load 2020 decennial census variables
v20 = load_variables(2020, "pl")

# Load 2019 1-year ACS profile variables
v19_profile = load_variables(2019, "acs1/profile")
```

# Notes
- Caching is recommended for repeated use as it significantly speeds up subsequent calls
- The function automatically filters for relevant Census variables (removes margin of error variables)
- For 5-year ACS datasets after 2010, geography information is included
- Variable names are cleaned to remove E and M suffixes (margin of error indicators)

# Full Dataset List
"sf1", "sf2", "sf3", "sf4", "pl", "dhc", "dp", "ddhca", "ddhcb", "sdhc", 
"as", "gu", "mp", "vi", "acsse", "dpas", "dpgu", "dpmp", "dpvi", "dhcvi", 
"dhcgu", "dhcvi", "dhcas", "acs1", "acs3", "acs5", "acs1/profile", 
"acs3/profile", "acs5/profile", "acs1/subject", "acs3/subject", 
"acs5/subject", "acs1/cprofile", "acs5/cprofile", "sf2profile", 
"sf3profile", "sf4profile", "aian", "aianprofile", "cd110h", "cd110s", 
"cd110hprofile", "cd110sprofile", "sldh", "slds", "sldhprofile", 
"sldsprofile", "cqr", "cd113", "cd113profile", "cd115", "cd115profile", 
"cd116", "cd118", "plnat"
"""
function load_variables(year::Int, dataset::String; cache::Bool=false)
    # Validate year format
    if !(1000 <= year <= 9999)
        error("Argument \"year\" must be a single year in format YYYY.")
    end
    
    # Validate dataset
    valid_datasets = [
        "sf1", "sf2", "sf3", "sf4", "pl", "dhc", "dp",
        "ddhca", "ddhcb", "sdhc", "as", "gu", "mp", "vi", "acsse",
        "dpas", "dpgu", "dpmp", "dpvi",
        "dhcvi", "dhcgu", "dhcvi", "dhcas",
        "acs1", "acs3", "acs5", "acs1/profile",
        "acs3/profile", "acs5/profile", "acs1/subject", "acs3/subject",
        "acs5/subject", "acs1/cprofile", "acs5/cprofile",
        "sf2profile", "sf3profile",
        "sf4profile", "aian", "aianprofile",
        "cd110h", "cd110s", "cd110hprofile", "cd110sprofile", "sldh",
        "slds", "sldhprofile", "sldsprofile", "cqr",
        "cd113", "cd113profile", "cd115", "cd115profile", "cd116",
        "plnat", "cd118"
    ]
    
    if !(dataset in valid_datasets)
        error("Invalid dataset. Must be one of: $(join(valid_datasets, ", "))")
    end
    
    # Check specific year/dataset combinations
    if year == 2020 && occursin("acs1", dataset)
        error("The 2020 1-year ACS was released as a set of experimental estimates that was not published to the Census API and is in turn not available.")
    end
    
    if year == 1990
        error("The 1990 decennial Census endpoint has been removed by the Census Bureau.")
    end
    
    if dataset == "sf3" && year > 2001
        error("Summary File 3 was not released in 2010. Use tables from the American Community Survey instead.")
    end
    
    if occursin("acs5", dataset) && year < 2009
        error("5-year ACS support begins with the 2005-2009 5-year ACS. Consider using decennial Census data instead.")
    end
    
    if occursin("acs1", dataset) && year < 2005
        error("1-year ACS support begins with the 2005 1-year ACS. Consider using decennial Census data instead.")
    end
    
    if occursin("acs3", dataset) && (year < 2007 || year > 2013)
        error("3-year ACS support begins with the 2005-2007 3-year ACS and ends with the 2011-2013 3-year ACS.")
    end
    
    # Prepare cache filename
    rds_name = replace(dataset, "/" => "_") * "_$year.json"
    
    # Parse dataset type if needed
    var_type = nothing
    if occursin("/", dataset)
        parts = split(dataset, "/")
        dataset = String(parts[1])
        var_type = String(parts[2])
    end
    
    # Adjust dataset path for API
    if dataset in ["sf1", "sf2", "sf3", "sf4", "pl", "ddhca", "ddhcb", "sdhc",
                   "as", "gu", "mp", "vi", "dhc", "dp",
                   "dpas", "dpgu", "dpmp", "dpvi",
                   "dhcvi", "dhcgu", "dhcvi", "dhcas",
                   "sf2profile", "sf3profile",
                   "sf4profile", "aian", "aianprofile",
                   "cd110h", "cd110s", "cd110hprofile", "cd110sprofile", "sldh",
                   "slds", "sldhprofile", "sldsprofile", "cqr",
                   "cd113", "cd113profile", "cd115", "cd115profile", "cd116",
                   "plnat", "cd118"]
        dataset = "dec/$dataset"
    end
    
    if dataset in ["acs1", "acs3", "acs5", "acsse"]
        dataset = "acs/$dataset"
    end
    
    if !isnothing(var_type)
        dataset = "$dataset/$var_type"
    end
    
    # Handle caching
    if cache
        cache_dir = get_cache_dir()
        if !isdir(cache_dir)
            mkpath(cache_dir)
        end
        
        file_loc = joinpath(cache_dir, rds_name)
        if isfile(file_loc)
            # Load from cache
            df = load_cached_data(file_loc)
            
            # Check if we need to refresh for 5-year ACS
            if year > 2010 && dataset == "acs/acs5" && !("geography" in names(df))
                df = get_dataset(dataset, year)
                save_cached_data(df, file_loc)
                return df
            end
            
            # Filter and process
            return process_dataset(df)
        else
            # Get new data and cache it
            df = get_dataset(dataset, year)
            save_cached_data(df, file_loc)
            return df
        end
    else
        return get_dataset(dataset, year)
    end
end

"""
    get_dataset(dataset::String, year::Int)

Fetch dataset from Census API and process it.
"""
function get_dataset(dataset::String, year::Int)
    set = "$year/$dataset"
    url = "https://api.census.gov/data/$set/variables.json"
    
    # Make HTTP request
    resp = HTTP.get(url)
    
    if resp.status == 404
        error("API endpoint not found. Does this data set exist for the specified year?")
    elseif resp.status != 200
        error("API request failed. Status code: $(resp.status)")
    end
    
    # Parse JSON
    data = JSON3.read(String(resp.body))
    
    # Convert to DataFrame
    variables = data["variables"]
    
    # Extract name, label, and concept
    names = String[]
    labels = String[]
    concepts = String[]
    
    for (name, var_data) in variables
        push!(names, String(name))
        push!(labels, get(var_data, "label", ""))
        push!(concepts, get(var_data, "concept", ""))
    end
    
    df = DataFrame(
        name = names,
        label = labels,
        concept = concepts
    )
    
    # Sort by name
    sort!(df, :name)
    
    # Filter for relevant variables
    df = filter_relevant_variables(df)
    
    # Add geography information for acs5
    if dataset == "acs/acs5" && year > 2010
        df = add_geography_info(df, year)
    end
    
    return df
end

"""
    filter_relevant_variables(df::DataFrame)

Filter dataset to include only relevant Census variables.
"""
function filter_relevant_variables(df::DataFrame)
    # Keep only variables matching Census patterns
    pattern = r"^[BCDHKPSTH][0-9]|^CP[0-9]|^DP[0-9]"
    df = df[occursin.(pattern, df.name), :]
    
    # Remove E and M suffixes using proper column replacement
    df[!, :name] = replace.(df.name, r"[EM]$" => "")
    
    # Remove margin of error rows
    df = df[.!occursin.(r"Margin [Oo]f Error", df.label), :]
    
    return df
end

"""
    process_dataset(df::DataFrame)

Process cached dataset with same filtering as fresh data.
"""
function process_dataset(df::DataFrame)
    # Apply same filtering as get_dataset
    return filter_relevant_variables(df)
end

"""
    add_geography_info(df::DataFrame, year::Int)

Add geography information for ACS5 datasets.

This function extracts table names from variable codes and adds a geography column
to the DataFrame. Currently, the geography column is populated with missing values
as a placeholder for future implementation of geography lookup functionality.

# Arguments
- `df::DataFrame`: DataFrame containing Census variables
- `year::Int`: Year of the dataset

# Returns
- `DataFrame`: DataFrame with added geography column

# Notes
- This function is called automatically for 5-year ACS datasets after 2010
- The geography column is currently a placeholder and contains missing values
- Future versions may include actual geography level information
"""
function add_geography_info(df::DataFrame, year::Int)
    # Extract table names using insertcols! for proper type handling
    insertcols!(df, :table => replace.(df.name, r"_.*" => ""))
    
    # This would require the geography lookup table
    # For now, adding placeholder column with proper type handling
    insertcols!(df, :geography => fill(missing, nrow(df)))
    
    # Remove temporary table column
    select!(df, Not(:table))
    
    return df
end

"""
    get_cache_dir()

Get the cache directory for storing Census data.
"""
function get_cache_dir()
    if Sys.iswindows()
        cache_base = get(ENV, "LOCALAPPDATA", get(ENV, "APPDATA", homedir()))
    elseif Sys.isapple()
        cache_base = joinpath(homedir(), "Library", "Caches")
    else  # Linux and others
        cache_base = get(ENV, "XDG_CACHE_HOME", joinpath(homedir(), ".cache"))
    end
    
    return joinpath(cache_base, "tidycensus_jl")
end

"""
    save_cached_data(df::DataFrame, filepath::String)

Save DataFrame to cache as JSON.

This function serializes a DataFrame containing Census variables to JSON format
for caching. Missing values in the geography column are converted to "MISSING"
strings to ensure proper JSON serialization.

# Arguments
- `df::DataFrame`: DataFrame containing Census variables to cache
- `filepath::String`: Path where the JSON cache file should be saved

# Notes
- Missing values are converted to "MISSING" strings for JSON compatibility
- The cache file contains variable names, labels, concepts, and geography data
- This function is called automatically when caching is enabled
"""
function save_cached_data(df::DataFrame, filepath::String)
    # Convert DataFrame to Dict for JSON serialization
    data = Dict(
        "names" => df.name,
        "labels" => df.label,
        "concepts" => df.concept
    )
    
    if "geography" in names(df)
        # For missing values, we'll store them as strings "MISSING" to avoid type issues
        geography_data = map(x -> x === missing ? "MISSING" : x, df.geography)
        data["geography"] = geography_data
    end
    
    open(filepath, "w") do io
        JSON3.write(io, data)
    end
end

"""
    load_cached_data(filepath::String)

Load DataFrame from cached JSON file.

This function deserializes a JSON cache file back into a DataFrame containing
Census variables. "MISSING" strings in the geography column are converted back
to missing values for proper DataFrame handling.

# Arguments
- `filepath::String`: Path to the JSON cache file to load

# Returns
- `DataFrame`: DataFrame containing Census variables with proper types

# Notes
- "MISSING" strings are converted back to missing values
- The function handles both vector and scalar geography data
- This function is called automatically when loading from cache
"""
function load_cached_data(filepath::String)
    data = JSON3.read(read(filepath, String))
    
    df = DataFrame(
        name = data["names"],
        label = data["labels"],
        concept = data["concepts"]
    )
    
    if haskey(data, "geography")
        # Ensure geography data is a vector before assignment
        geography_data = data["geography"]
        
        if !(geography_data isa Vector)
            # If it's a scalar, create a vector with the same value for all rows
            geography_data = fill(geography_data, nrow(df))
        end
        
        # Convert "MISSING" strings back to missing for DataFrame
        geography_data = map(x -> x == "MISSING" ? missing : x, geography_data)
        
        # Use insertcols! to properly handle type conversion
        insertcols!(df, :geography => geography_data)
    end
    
    return df
end

export load_variables