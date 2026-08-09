### GA4 Raw Data Transformation

Welcome! This is a project which builds a data model from the raw GA4 data to be used in BI solutions. 

Below are the key key tables that are spat out of this report: 
- A source/medium report 
- A Custom Channel Grouping Report 
- A Campaign-level report (including source medium information)
- A Landing Page Report
- Page Journey Report 
- A customer retention report 
- A customer source channel journey report (the usual paths customers take to visit the site in a sequence). 
- A/B Test table

The core data model contains the following tables. More will be added later. 

Dimensions: 
- Date table 
- Source Table 
- Medium Table 
- Channel Grouping Table 
- Campaign Table
- User Table
- Page Table
- URL Table (Not sure on this since this will be high cardinality because of the random URL parameters) 
- A/B Test Name 
- A/B Test Variant (This may be redundant since I'll only have 'test' and 'control')

Facts Table: 
- Session Table
    - Key: session_id 
    - Dimensions: 
        date_id 
        campaign_id
        source_id
        medium_id
        channel_grouping_id 
        landing_page_url_id 
    - Metrics: 
        sessions 
        users
        new_users
        bounces #This will be used to calculate bounce rate, and engagement rate in the BI tool. 
        total_session_duration_time #This will be used to calculate the avg session duration within the BI tool.  
- Page Views Event
- Events Table
- A/B Test table
    - Key: ab_test_name_id
    - Dimensions: 
        date
        ab_test_variant_id
    - Metrics: 
        sessions #Events to be considered will be defined dynamically from a seed table. 
        conversions #The conversion event would be defined dynamically from a seed table. 
- User Retention Table 
- User source/medium journey