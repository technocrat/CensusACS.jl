"""
    format_geoids_for_sql(geoids::Vector{String}) -> String

Format a vector of GEOIDs into a string suitable for use in a SQL IN clause.
Each GEOID is wrapped in parentheses and single quotes, separated by commas.

# Arguments
- `geoids::Vector{String}`: Vector of GEOID strings to format

# Returns
- `String`: Formatted string of GEOIDs

# Example
```julia
geoids = ["53001", "53003", "53005"]
result = format_geoids_for_sql(geoids)
# Returns: "('53001'), ('53003'), ('53005')"
```
"""
function format_geoids_for_sql(geoids::Vector{String})
    formatted = join(["('$g')" for g in geoids], ", ")
    return formatted
end 