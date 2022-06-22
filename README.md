[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=0.20.x&color=orange)

# Chronic Conditions

Check out the latest [DAG](https://tuva-health.github.io/chronic_conditions/#!/overview?g_v=1)

Check out our [Docs](http://thetuvaproject.com/)

This concept package creates patient-level chronic condition flags based on the definitions from the [CMS Chronic Conditions Warehouse (CCW)](https://www2.ccwdata.org/web/guest/condition-categories). The package identifies and flags 75 different chronic conditions grouped into 9 clinical categories. _Note: The logic implemented in this package is more broad and inclusive of claim types and dates than the CMS definition._

There are two main output tables from this package:
1) A "long" table with all qualifying encounters per patient-condition, and 
2) A "wide" table with one record per patient and each condition flag as a separate column.

## Pre-requisites
1. You have healthcare data (e.g. EHR, claims, lab, HIE, etc.) in a data warehouse
2. You have [dbt](https://www.getdbt.com/) installed and configured (i.e. connected to your data warehouse)

[Here](https://docs.getdbt.com/dbt-cli/installation) are instructions for installing dbt.

## Configuration
Execute the following steps to load all seed files, build all data marts, and run all data quality tests in your data warehouse:

1. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) this repo to your local machine or environment
2. This project will run automatically off of [Tuva Core](https://github.com/tuva-health/core).
3. Alternatively, if you haven't installed Tuva Core you can directly map your data to the source schema described in [source.yml](models/source.yml)
4. Configure [dbt_project.yml](/dbt_project.yml)
    - profile: set to 'tuva' by default - change this to an active profile in the profile.yml file that connects to your data warehouse
    - vars: configure source_name, source database name, and source schema name
5. Run project
    1. Navigate to the project directory in the command line
    2. Execute "dbt build" to create all tables/views in your data warehouse

## Contributions
Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing 
and running the package? If so, we highly encourage and welcome contributions to this package! 

Join the conversation on [Slack](https://tuvahealth.slack.com/ssb/redirect#/shared-invite/email)!

## Database Support
This package has been tested on Snowflake and Redshift.  We are planning to expand testing to BigQuery in the near future.
