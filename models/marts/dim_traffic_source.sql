{{ config(materialized='table') }}

-- Channel grouping follows Google's documented default channel groups
-- (https://support.google.com/analytics/answer/9756891), manual-attribution
-- rules only -- this pipeline has no Google Ads/DV360/SA360 platform data, so
-- the ad-network/campaign-type rules from that doc don't apply here.
-- Search/social/video source matching below is a curated subset of the major
-- sources, not Google's full 800+ site reference list -- expected to be
-- refined later.

with sources as (

    select distinct
        session_source,
        session_medium,
        session_campaign_name
    from {{ ref('int_sessions') }}

),

classified as (

    select
        session_source as source,
        session_medium as medium,
        session_campaign_name as campaign,
        case
            when lower(session_source) = '(direct)'
                and lower(session_medium) in ('(not set)', '(none)')
                then 'Direct'
            when regexp_contains(lower(session_medium), r'.*cp.*|ppc|retargeting|paid.*')
                and regexp_contains(lower(session_source), r'google|bing|yahoo|duckduckgo|baidu|yandex|ecosia|aol|ask')
                then 'Paid Search'
            when regexp_contains(lower(session_medium), r'.*cp.*|ppc|retargeting|paid.*')
                and regexp_contains(lower(session_source), r'facebook|instagram|twitter|linkedin|pinterest|tiktok|reddit|snapchat|quora')
                then 'Paid Social'
            when regexp_contains(lower(session_medium), r'.*cp.*|ppc|retargeting|paid.*')
                and regexp_contains(lower(session_source), r'youtube|vimeo|dailymotion|twitch')
                then 'Paid Video'
            when lower(session_medium) in ('display', 'cpm', 'banner')
                then 'Display'
            when regexp_contains(lower(session_medium), r'.*cp.*|ppc|retargeting|paid.*')
                then 'Paid Other'
            when lower(session_medium) = 'organic'
                or regexp_contains(lower(session_source), r'google|bing|yahoo|duckduckgo|baidu|yandex|ecosia|aol|ask')
                then 'Organic Search'
            when lower(session_medium) in ('social', 'social-network', 'social-media', 'sm')
                or regexp_contains(lower(session_source), r'facebook|instagram|twitter|linkedin|pinterest|tiktok|reddit|snapchat|quora')
                then 'Organic Social'
            when regexp_contains(lower(session_medium), r'video')
                or regexp_contains(lower(session_source), r'youtube|vimeo|dailymotion|twitch')
                then 'Organic Video'
            when lower(session_source) in ('email', 'e-mail', 'e_mail')
                or lower(session_medium) in ('email', 'e-mail')
                then 'Email'
            when lower(session_medium) = 'affiliate'
                then 'Affiliates'
            when lower(session_medium) = 'audio'
                then 'Audio'
            when lower(session_source) = 'sms'
                or lower(session_medium) = 'sms'
                then 'SMS'
            when lower(session_medium) like '%push%'
                or lower(session_medium) like '%mobile%'
                or lower(session_medium) like '%notification%'
                or lower(session_source) = 'firebase'
                then 'Mobile Push Notifications'
            when lower(session_medium) in ('referral', 'app', 'link')
                then 'Referral'
            else 'Unassigned'
        end as channel_grouping
    from sources

)

select
    map.id as traffic_source_id,
    classified.source,
    classified.medium,
    classified.campaign,
    classified.channel_grouping
from classified
left join {{ ref('traffic_source_id_map') }} map
    on {{ business_key_expr(['classified.source', 'classified.medium', 'classified.campaign']) }} = map.business_key
