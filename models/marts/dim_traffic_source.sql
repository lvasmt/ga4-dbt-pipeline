{{ config(materialized='table') }}

-- Channel grouping follows Google's documented default channel groups
-- (https://support.google.com/analytics/answer/9756891), manual-attribution
-- rules only -- this pipeline has no Google Ads/DV360/SA360 platform data, so
-- the ad-network/campaign-type rules from that doc don't apply here.
-- Search/social/video source matching below is a curated subset of the major
-- sources, not Google's full 800+ site reference list -- expected to be
-- refined later.
--
-- Deliberate departures from GA4's defaults:
--   * (not set) / null source with no real medium is treated as Direct. GA4's
--     own UI reports these as Unassigned.
--   * AI Assistant: GA4's own rule is medium = 'ai-assistant' (GA4 sets that
--     medium itself when the referrer is on its AI assistant list). A source
--     match on known assistants is added as a fallback, for sessions from
--     before GA4 introduced the channel and assistants not on Google's list.
--     Checked right after Direct so e.g. gemini.google.com isn't caught by
--     the search rules.
--   * Search engine sources are matched on the domain itself (anchored regex),
--     not as a substring, so e.g. tagmanager.google.com falls through to
--     Referral instead of Organic Search.

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
        concat(
            coalesce(session_source, '(not set)'),
            ' / ',
            coalesce(session_medium, '(not set)')
        ) as source_medium,
        case
            when (session_source is null or lower(session_source) in ('(direct)', '(not set)'))
                and (session_medium is null or lower(session_medium) in ('(not set)', '(none)'))
                then 'Direct'
            when lower(session_medium) = 'ai-assistant'
                or regexp_contains(
                    lower(session_source),
                    r'chatgpt|openai|perplexity|claude\.ai|anthropic|gemini\.google|bard\.google|copilot\.microsoft|deepseek|meta\.ai|grok|mistral\.ai|you\.com|poe\.com|phind'
                )
                then 'AI Assistant'
            when regexp_contains(lower(session_medium), r'.*cp.*|ppc|retargeting|paid.*')
                and regexp_contains(lower(session_source), r'^((www|search|m)\.)?(google|bing|yahoo|duckduckgo|baidu|yandex|ecosia|aol|ask)(\.[a-z]{2,3}){0,2}$')
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
                or regexp_contains(lower(session_source), r'^((www|search|m)\.)?(google|bing|yahoo|duckduckgo|baidu|yandex|ecosia|aol|ask)(\.[a-z]{2,3}){0,2}$')
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
    classified.source_medium,
    classified.channel_grouping
from classified
left join {{ ref('traffic_source_id_map') }} map
    on {{ business_key_expr(['classified.source', 'classified.medium', 'classified.campaign']) }} = map.business_key
