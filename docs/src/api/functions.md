# API Reference

This page documents the public API for ACS.jl.

## Main Data Retrieval Functions

These are the primary functions for retrieving ACS data:

```@docs
get_acs
get_acs1
get_acs3
get_acs5
```

## Margin of Error Functions

Functions specifically for retrieving margin of error data:

```@docs
get_acs_moe
get_acs_moe1
get_acs_moe3
get_acs_moe5
```

## Additional Functions

Other useful functions provided by the package:

```@docs
get_tiger_shapefile
```

## Function Overview

### Main Functions
- `get_acs()` - General ACS data retrieval function
- `get_acs1()` - 1-year ACS estimates (2005-present, except 2020)
- `get_acs3()` - 3-year ACS estimates (2007-2013)
- `get_acs5()` - 5-year ACS estimates (2009-present)

### Margin of Error Functions
- `get_acs_moe()` - General MOE data retrieval function
- `get_acs_moe1()` - 1-year ACS margins of error
- `get_acs_moe3()` - 3-year ACS margins of error
- `get_acs_moe5()` - 5-year ACS margins of error

### Utility Functions
- `get_tiger_shapefile()` - Download Census TIGER shapefiles
- `state_postal_to_fips()` - Convert state postal codes to FIPS codes
- `build_census_url()` - Build Census API URLs
- `make_census_request()` - Make requests to Census API
