/*
SNOWFLAKE ANALYSIS SCRIPT
*/

-- Set role, context, and warehouse
USE ROLE ROLE_HOL_TIMESERIES;
USE HOL_TIMESERIES.ANALYTICS;
USE WAREHOUSE HOL_ANALYTICS_WH;

-- Run Time Series Analysis across various query profiles

-- RAW
SELECT TAGNAME, TIMESTAMP, VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP >= '2024-01-01 00:00:00'
AND TIMESTAMP < '2024-01-01 00:00:10'
AND TAGNAME = '/IOT/SENSOR/TAG301'
ORDER BY TAGNAME, TIMESTAMP
;

-- STATISTICAL AGGREGATES, DISTRIBUTIONS, AND WATERMARKS
/* COUNT AND COUNT DISTINCT
Retrieve counts within the time boundary
COUNT - Count of all values
COUNT DISTINCT - Count of unique values
Counts can work with both varchar and numeric data types
*/
SELECT TAGNAME, TO_TIMESTAMP_NTZ('2024-01-01 01:00:00') AS TIMESTAMP,
    COUNT(VALUE) AS COUNT_VALUE,
    COUNT(DISTINCT VALUE) AS COUNT_DISTINCT_VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
ORDER BY TAGNAME
;

/* MIN/MAX/AVG/SUM/APPROX_PERCENTILE
Retrieve statistical aggregates for the readings within the time boundary
MIN - Minimum value
MAX - Maximum value
AVG - Average of values (mean)
SUM - Sum of values
PERCENTILE_50 - 50% of values are less than this
PERCENTILE_95 - 95% of values are less than this
Aggregates can work with numerical data types
*/
SELECT TAGNAME, TO_TIMESTAMP_NTZ('2024-01-01 01:00:00') AS TIMESTAMP,
    MIN(VALUE_NUMERIC) AS MIN_VALUE,
    MAX(VALUE_NUMERIC) AS MAX_VALUE,
    SUM(VALUE_NUMERIC) AS SUM_VALUE,
    AVG(VALUE_NUMERIC) AS AVG_VALUE,
    APPROX_PERCENTILE(VALUE_NUMERIC, 0.5) AS PERCENTILE_50_VALUE,
    APPROX_PERCENTILE(VALUE_NUMERIC, 0.95) AS PERCENTILE_95_VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS 
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
ORDER BY TAGNAME
;

/* DISTRIBUTIONS - sample distributions statistics
Retrieve distribution sample statistics within the time boundary
STDDEV - Closeness to the mean/average of the distribution
VARIANCE - Spread between numbers in the time boundary
KURTOSIS - Measure of outliers occuring
SKEW - Left (negative) and right (positive) distribution skew
Distributions can work with numerical data types
*/
SELECT TAGNAME || '~STDDEV_1HOUR' AS TAGNAME, TO_TIMESTAMP_NTZ('2024-01-01 01:00:00') AS TIMESTAMP, STDDEV(VALUE_NUMERIC) AS VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
UNION ALL
SELECT TAGNAME || '~VARIANCE_1HOUR' AS TAGNAME, TO_TIMESTAMP_NTZ('2024-01-01 01:00:00') AS TIMESTAMP, VARIANCE(VALUE_NUMERIC) AS VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
UNION ALL
SELECT TAGNAME || '~KURTOSIS_1HOUR' AS TAGNAME, TO_TIMESTAMP_NTZ('2024-01-01 01:00:00') AS TIMESTAMP, KURTOSIS(VALUE_NUMERIC) AS VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
UNION ALL
SELECT TAGNAME || '~SKEW_1HOUR' AS TAGNAME, TO_TIMESTAMP_NTZ('2024-01-01 01:00:00') AS TIMESTAMP, SKEW(VALUE_NUMERIC) AS VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
ORDER BY TAGNAME
;

/* WATERMARKS
Retrieve both the high and low watermark readings within the time boundary
MAX_BY - High Watermark - latest reading in the time boundary
MIN_BY - Low Watermark - earliest reading in the time boundary
*/ 
SELECT TAGNAME || '~MAX_BY_1HOUR' AS TAGNAME, MAX_BY(TIMESTAMP, TIMESTAMP) AS TIMESTAMP, MAX_BY(VALUE, TIMESTAMP) AS VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
UNION ALL
SELECT TAGNAME || '~MIN_BY_1HOUR' AS TAGNAME, MIN_BY(TIMESTAMP, TIMESTAMP) AS TIMESTAMP, MIN_BY(VALUE, TIMESTAMP) AS VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 01:00:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TAGNAME
ORDER BY TAGNAME
;

/* WINDOW FUNCTIONS
LAG - Prior time period value
LEAD - Next time period value
*/
SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC AS VALUE,
    LAG(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP) AS LAG_VALUE,
    LEAD(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP) AS LEAD_VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP >= '2024-01-01 00:00:00'
AND TIMESTAMP < '2024-01-01 00:00:10'
AND TAGNAME = '/IOT/SENSOR/TAG301'
ORDER BY TAGNAME, TIMESTAMP
;

/* ROWS BETWEEN
ROW_SUM_PRECEDING - Rolling sum from 5 preceding rows and current row
ROW_SUM_FOLLOWING - Rolling sum from current row and 5 following rows
*/
SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC AS VALUE,
    SUM(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS ROW_SUM_PRECEDING,
    SUM(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP
        ROWS BETWEEN CURRENT ROW AND 5 FOLLOWING) AS ROW_SUM_FOLLOWING
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP >= '2024-01-01 00:00:00'
AND TIMESTAMP < '2024-01-01 00:00:10'
AND TAGNAME = '/IOT/SENSOR/TAG301'
ORDER BY TAGNAME, TIMESTAMP
;

/* RANGE BETWEEN
INTERVAL - Natural time input intervals
*/
SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC AS VALUE,
    SUM(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP
        RANGE BETWEEN INTERVAL '5 SEC' PRECEDING AND CURRENT ROW) AS RANGE_SUM_PRECEDING,
    SUM(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP
        RANGE BETWEEN CURRENT ROW AND INTERVAL '5 SEC' FOLLOWING) AS RANGE_SUM_FOLLOWING
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 00:00:10'
AND TAGNAME = '/IOT/SENSOR/TAG301'
ORDER BY TAGNAME, TIMESTAMP
;

/* RANGE BETWEEN
INTERVAL - 10 second tag with 25 seconds preceding SUM
*/
SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC AS VALUE,
    SUM(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP
        RANGE BETWEEN INTERVAL '25 SEC' PRECEDING AND CURRENT ROW) AS RANGE_SUM_PRECEDING
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP > '2024-01-01 00:00:00'
AND TIMESTAMP <= '2024-01-01 00:01:40'
AND TAGNAME = '/IOT/SENSOR/TAG201'
ORDER BY TAGNAME, TIMESTAMP
;

/* FIRST_VALUE AND LAST_VALUE
FIRST_VALUE - First value in the time boundary
LAST_VALUE - Last value in the time boundary
*/
SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC AS VALUE, 
    FIRST_VALUE(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP) AS FIRST_VALUE,
    LAST_VALUE(VALUE_NUMERIC) OVER (
        PARTITION BY TAGNAME ORDER BY TIMESTAMP) AS LAST_VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP >= '2024-01-01 00:00:00'
AND TIMESTAMP < '2024-01-01 00:00:10'
AND TAGNAME = '/IOT/SENSOR/TAG301'
ORDER BY TAGNAME, TIMESTAMP
;

/* TIME GAP FILLING
Generate time stamps given a start and end time boundary, and join to a tag with less frequent values.
TIME_PERIODS - variable passed into query to determine time stamps generated for gap filling
*/
SET TIME_PERIODS = (SELECT TIMESTAMPDIFF('SECOND', '2024-01-01 00:00:00'::TIMESTAMP_NTZ, '2024-01-01 00:00:00'::TIMESTAMP_NTZ + INTERVAL '1 MINUTE'));

-- LAST OBSERVED VALUE CARRIED FORWARD (LOCF) - IGNORE NULLS
WITH TIMES AS (
    SELECT
    DATEADD('SECOND', ROW_NUMBER() OVER (ORDER BY SEQ8()) - 1, '2024-01-01')::TIMESTAMP_NTZ AS TIMESTAMP
    FROM TABLE(GENERATOR(ROWCOUNT => $TIME_PERIODS))
),
DATA AS (
    SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC AS VALUE,
    FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
    WHERE TIMESTAMP >= '2024-01-01 00:00:00'
    AND TIMESTAMP < '2024-01-01 00:01:00'
    AND TAGNAME = '/IOT/SENSOR/TAG101'
)
SELECT TIMES.TIMESTAMP,
    A.TAGNAME AS TAGNAME,
    B.VALUE,
    A.VALUE AS LOCF_VALUE
FROM TIMES
LEFT JOIN DATA B ON TIMES.TIMESTAMP = B.TIMESTAMP
ASOF JOIN DATA A MATCH_CONDITION(TIMES.TIMESTAMP >= A.TIMESTAMP)
ORDER BY TAGNAME, TIMESTAMP;

/* TIME BINNING - 1 min AGGREGATE with START label
Create a downsampled time series data set with 1 minute aggregates, showing the START timestamp label of the interval
COUNT - Count of values within the time bin
SUM - Sum of values within the time bin
AVG - Average of values (mean) within the time bin
PERCENTILE_95 - 95% of values are less than this within the time bin
*/
SELECT TAGNAME, TIME_SLICE(TIMESTAMP, 1, 'MINUTE', 'START') AS TIMESTAMP,
    COUNT(*) AS COUNT_VALUE,
    SUM(VALUE_NUMERIC) AS SUM_VALUE,
    AVG(VALUE_NUMERIC) AS AVG_VALUE,
    APPROX_PERCENTILE(VALUE_NUMERIC, 0.95) AS PERCENTILE_95_VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP >= '2024-01-01 00:00:00'
AND TIMESTAMP < '2024-01-01 00:10:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TIME_SLICE(TIMESTAMP, 1, 'MINUTE', 'START'), TAGNAME
ORDER BY TAGNAME, TIMESTAMP
;

/* TIME BINNING - 1 min AGGREGATE with END label
Same as before, but now showing the END timestamp label of the interval
COUNT - Count of values within the time bin
SUM - Sum of values within the time bin
AVG - Average of values (mean) within the time bin
PERCENTILE_95 - 95% of values are less than this within the time bin
*/
SELECT TAGNAME, TIME_SLICE(TIMESTAMP, 1, 'MINUTE', 'END') AS TIMESTAMP,
    COUNT(*) AS COUNT_VALUE,
    SUM(VALUE_NUMERIC) AS SUM_VALUE,
    AVG(VALUE_NUMERIC) AS AVG_VALUE,
    APPROX_PERCENTILE(VALUE_NUMERIC, 0.95) AS PERCENTILE_95_VALUE
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
WHERE TIMESTAMP >= '2024-01-01 00:00:00'
AND TIMESTAMP < '2024-01-01 00:10:00'
AND TAGNAME = '/IOT/SENSOR/TAG301'
GROUP BY TIME_SLICE(TIMESTAMP, 1, 'MINUTE', 'END'), TAGNAME
ORDER BY TAGNAME, TIMESTAMP
;

/* ASOF JOIN - Align a 1sec tag with a 5sec tag
Using the ASOF JOIN two data sets can be aligned by applying a matching condition to pair closely aligned timestamps and values.
*/
SELECT ONE_SEC.TAGNAME AS ONE_SEC_TAGNAME, ONE_SEC.TIMESTAMP AS ONE_SEC_TIMESTAMP, ONE_SEC.VALUE_NUMERIC AS ONE_SEC_VALUE, FIVE_SEC.VALUE_NUMERIC AS FIVE_SEC_VALUE, FIVE_SEC.TAGNAME AS FIVE_SEC_TAGNAME, FIVE_SEC.TIMESTAMP AS FIVE_SEC_TIMESTAMP
FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS ONE_SEC
ASOF JOIN (
    -- 5 sec tag data
    SELECT TAGNAME, TIMESTAMP, VALUE_NUMERIC
    FROM HOL_TIMESERIES.ANALYTICS.TS_TAG_READINGS
    WHERE TAGNAME = '/IOT/SENSOR/TAG101'
    ) FIVE_SEC
MATCH_CONDITION(ONE_SEC.TIMESTAMP >= FIVE_SEC.TIMESTAMP)
WHERE ONE_SEC.TAGNAME = '/IOT/SENSOR/TAG301'
AND ONE_SEC.TIMESTAMP >= '2024-01-01 00:00:00'
AND ONE_SEC.TIMESTAMP < '2024-01-01 00:01:00'
ORDER BY ONE_SEC.TIMESTAMP;

/*
ANALYSIS SCRIPT COMPLETED
*/