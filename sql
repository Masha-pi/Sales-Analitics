WITH a AS (

SELECT
a.is_verified AS is_verified ,
a.is_unsubscribed AS is_unsubscribed,
send_interval,
COUNTRY,
DATE_ADD(ss.date, INTERVAL es.sent_date DAY) AS s_date,
COUNT(DISTINCT es.id_message) AS email_sent,
COUNT(DISTINCT eo.id_message) AS email_open,
COUNT(DISTINCT ev.id_message) AS email_visit,
NULL AS  account_cnt
FROM `DA.session_params` sp
JOIN `DA.session` ss
ON sp.ga_session_id = ss.ga_session_id
JOIN `DA.account_session` acs
ON acs.ga_session_id = ss.ga_session_id
JOIN `DA.account` a
ON acs.account_id = a.id
JOIN `DA.email_sent` es
ON a.id = es.id_account
LEFT JOIN `DA.email_open` eo
ON es.id_message = eo.id_message
LEFT JOIN `DA.email_visit` ev
ON eo.id_message = ev.id_message
GROUP BY 1,2,3,4,5


UNION ALL

SELECT
is_verified,
is_unsubscribed,
send_interval,
country,
s.date AS s_date,
NULL AS email_sent,
NULL AS email_open,
NULL AS email_visit,


COUNT(a.id) AS account_cnt

FROM `DA.session_params` sp
JOIN `DA.session` s
ON sp.ga_session_id = s.ga_session_id
JOIN `DA.account_session` acs
ON acs.ga_session_id = s.ga_session_id
JOIN `DA.account` a
ON acs.account_id = a.id
GROUP BY 1,2,3,4,5

),

b AS (
  SELECT
  s_date,
  is_verified,
  is_unsubscribed,
  send_interval,
  country,
  account_cnt,
  email_sent,
  email_open,
  email_visit,
  SUM(account_cnt) OVER(PARTITION BY country) AS total_country_account_cnt,
  SUM(email_sent) OVER(PARTITION BY country ) AS total_country_sent_cnt
FROM a
)




SELECT
 *
FROM (
-- основній запит що надає ранг
SELECT
s_date,
is_verified,
is_unsubscribed,
send_interval,
country,
account_cnt,
email_sent,
email_open,
email_visit,
total_country_account_cnt,
total_country_sent_cnt,
DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_sent_account_cnt  
FROM b
)
where rank_total_country_account_cnt <= 10 or rank_total_sent_account_cnt <= 10


