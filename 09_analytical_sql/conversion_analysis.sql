-- Session conversion analysis. Dataset conversion flag is stored on core.sessions.

-- Overall conversion rate
SELECT COUNT(*) AS total_sessions,
       COUNT(*) FILTER (WHERE converted IS TRUE) AS converted_sessions,
       COUNT(*) FILTER (WHERE converted IS FALSE) AS non_converted_sessions,
       ROUND(100.0 * COUNT(*) FILTER (WHERE converted IS TRUE) / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
FROM core.sessions;

-- Conversion by channel and device
SELECT channel, device, COUNT(*) AS sessions,
       COUNT(*) FILTER (WHERE converted IS TRUE) AS converted_sessions,
       ROUND(100.0 * COUNT(*) FILTER (WHERE converted IS TRUE) / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
FROM core.sessions
GROUP BY channel, device
ORDER BY conversion_rate_pct DESC;

-- Average pages viewed by conversion outcome
SELECT converted, COUNT(*) AS sessions,
       AVG(pages_viewed) AS average_pages_viewed
FROM core.sessions
GROUP BY converted ORDER BY converted;
