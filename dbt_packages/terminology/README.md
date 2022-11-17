[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.x&color=orange)

# Terminology

This is The Tuva Project's terminology package, a single source of truth for all terminology datasets used and maintained by The Tuva Project.  You can load all of the terminology datasets contained in this repository into your data warehouse with a single command.

Knowledge Base:
- Check out the [catalog](https://thetuvaproject.com/docs/terminology) of all terminology sets included in this repository

## Getting Started
This is a [dbt](https://www.getdbt.com/) package, designed for use as part of an existing dbt project.  For help getting started with dbt, see the [dbt getting started guide](https://docs.getdbt.com/docs/get-started/getting-started/overview).  

Complete the following steps to configure the package to run in your environment.

1. Create a **packages.yml** file in your dbt project, and add the following
```
packages:
  - package: tuva-health/terminology
    version: 0.1.0
```
2. Run ``dbt deps`` to load this package into your project.  To use default behavior, skip to step 6.
3. Optional: Define a custom database name in dbt_project.yml
    - By default, terminology seeds will be written to a `tuva` database 
    - To override the default database for all Tuva packages, add a `tuva_database` variable to your dbt_project.yml
      ```
      vars:
        tuva_database: tuva_test_db
      ```
    - To override the default database for the terminology package only, add a `terminology_schema` variable. This will take precedence over `tuva_database`
      ```
      vars:
        terminology_database: tuva_terminology  # terminology will be written to this database
        tuva_database: tuva_marts               # all other packages will be written to this database
      ```

4. Optional: Define custom schema in dbt_project.yml 
    - By default, terminology seeds will be written to a `terminology` schema 
    - To prepend a prefix to all default schemas in tuva packages, add a `tuva_schema_prefix` variable to your dbt_project.yml.  This will write the terminology seeds to a `<tuva_schema_prefix>_terminology` schema
      ```
      vars:
        tuva_schema_prefix: new_source_test     # terminology will be written to a new_source_test_terminology schema
      ```
    - To override the default schema for the terminology package only, add a `terminology_schema` variable. This will take precedence over tuva_schema_prefix.
      ```
      vars:
        terminology_schema: healthcare_terminology
      ```
5. Optional: disable packages in dbt_project.yml
   - To disable all tuva packages, add a `tuva_packages_enabled` variable and set it to `False`
      ```
      vars:
        tuva_packages_enabled: False
      ```
   - To disable the terminology package only, add a `terminology_enabled` variable and set it to `False`
      ```
      vars:
        terminology_enabled: False
      ```
   - `terminology_enabled` will take precedence over `tuva_packages_enabled`, so you have the option of disabling all tuva packages except those explicitly enabled
      ```
      vars:
        tuva_packages_enabled: False
        terminology_enabled: True
      ```
6. Execute `dbt seed` to load all terminology sets to your warehouse
   - Alternatively, execute `dbt build` to load all seeds _and_ run the entire project 
   - To load a single seed file, use select model name syntax, e.g.: `dbt seed --select terminology__gender.csv`
   - To load only terminology files required by a specific Tuva package, use the pagkage name as a tag, e.g.: `dbt seed --select 'tag:readmissions'`
