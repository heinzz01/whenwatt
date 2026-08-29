-- ============================================================
-- Two saved queries -> two Query API Endpoints.
--
-- For each one, in the SQL console:
--   1. paste it into a new tab
--   2. fill the parameter boxes on the right, hit Run, check it works
--   3. Save (name it as in the comment)
--   4. Share -> API Endpoint
--        - pick your API key
--        - Database role: READ ONLY   <- important, the key ends up in the browser
--        - CORS allowed domain: https://<your-site>.netlify.app
--   5. copy the endpoint id out of the curl command it shows you
-- ============================================================


-- ============================================================
-- QUERY 1  ·  save as "hourly_curve"
-- Feeds the chart and the headline answer.
-- Every call is a different slice: different country, different month.
-- ============================================================

SELECT
    local_hour,
    round(avg(eur_per_mwh), 1) AS eur_per_mwh,
    round(avg(g_co2_per_kwh), 0) AS g_co2_per_kwh
FROM grid_hourly
WHERE country = {country:String}
  AND toMonth(ts) = {month:UInt8}
GROUP BY local_hour
ORDER BY local_hour;


-- ============================================================
-- QUERY 2  ·  save as "appliance_ranking"
-- THE one to show a ClickHouse judge.
--
-- One query, two databases: the appliance list lives in Postgres
-- (OLTP, changes constantly), the six years of prices live in
-- ClickHouse (OLAP, immutable). ClickHouse reads Postgres directly
-- through the postgresql() table function - no ETL, no copy job.
--
-- Sorted by annual saving, so the answer is the ranking itself:
-- the car and the heat pump at the top, the kettle at the bottom.
--
-- Replace the postgresql() arguments with your Managed Postgres
-- host, database, user and password.
-- ============================================================

SELECT
    a.name                                                            AS appliance,
    a.kwh_per_run                                                     AS kwh,
    argMin(g.local_hour, g.eur)                                       AS best_hour,
    argMax(g.local_hour, g.eur)                                       AS worst_hour,
    round(a.kwh_per_run * (max(g.eur) - min(g.eur)) / 1000, 2)        AS save_per_run_eur,
    round(a.kwh_per_run * (max(g.co2) - min(g.co2)) / 1000, 2)        AS save_per_run_kg,
    round(a.kwh_per_run * (max(g.eur) - min(g.eur)) / 1000
          * a.runs_per_month * 12, 0)                                 AS save_per_year_eur
FROM
(
    SELECT local_hour, avg(eur_per_mwh) AS eur, avg(g_co2_per_kwh) AS co2
    FROM grid_hourly
    WHERE country = {country:String} AND toMonth(ts) = {month:UInt8}
    GROUP BY local_hour
) AS g
CROSS JOIN postgresql('<pg-host>:5432', '<pg-db>', 'appliances',
                      '<pg-user>', '<pg-password>') AS a
WHERE a.shiftable
GROUP BY a.name, a.kwh_per_run, a.runs_per_month
ORDER BY save_per_year_eur DESC;
