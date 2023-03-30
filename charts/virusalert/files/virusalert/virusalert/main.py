from __future__ import annotations
import yagmail
import yagmail.dkim
import elasticsearch
from decouple import config
import threading
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from time import sleep
from typing import Any
import logging
from humanize import *

es = elasticsearch.Elasticsearch(
    hosts = config("ES_HOSTS"),
    http_auth = (config("ES_USER"), config("ES_PASSWORD")),
    verify_certs = False,
)

# if any(config(param, default=None) for param in ("DKIM_DOMAIN", "DKIM_KEY", "DKIM_SELECTOR")):
#     dkim = yagmail.dkim.DKIM(
#         domain = config("DKIM_DOMAIN").encode('ascii'),
#         private_key = config("DKIM_KEY").encode('ascii'),
#         include_headers = None,
#         selector = config("DKIM_SELECTOR").encode('ascii'),
#     )
# else:
#     dkim = None

smtp = yagmail.SMTP(
    user = config("SMTP_USER"),
    password = config("SMTP_PASSWORD"),
    host = config("SMTP_HOST"),
    port = config("SMTP_PORT", default=None),
    # dkim = dkim,
)

@dataclass
class Alerter:
    scan_interval: timedelta = timedelta(seconds=5)
    scan_window: timedelta = timedelta(minutes=5)
    alert_interval: timedelta = timedelta(minutes=5)
    allowed_threat_interval: timedelta = timedelta(seconds=10) # only alert if more threats than 1>allowed_threat_interval
    
    last_scan_time: datetime = field(default_factory=datetime.now)
    next_scan_time: datetime = field(default_factory=datetime.now)
    last_alert_time: datetime = field(default_factory=datetime.now)
    next_alert_time: datetime = field(default_factory=datetime.now)

    log: logging.Logger = logging.getLogger("alerter")

    def loop(self, now: datetime = None) -> datetime:
        if now is None: now = datetime.now()

        alert_cooldown = now >= self.next_alert_time
        scan_cooldown = now >= self.next_scan_time

        if alert_cooldown and scan_cooldown:
            scan_begin = min(self.last_scan_time, self.last_alert_time, now - self.scan_window)
            scan_end = now

            scan_result = self.scan(begin=scan_begin, end=scan_end)
            self.last_scan_time = now
            self.next_scan_time = now + self.scan_interval

            analysis = self.analyze(s=scan_result, query_info=locals())

            trigger = self.trigger(analysis)

            if trigger:
                self.alert(analysis)
                self.last_alert_time = now
                self.next_alert_time = now + self.alert_interval

        
        may_sleep_until = max(self.next_alert_time, self.next_scan_time)
        return may_sleep_until

    def scan(self, begin: datetime = None, end: datetime = None) -> dict[str,Any]:
        self.log.info(f"Scanning from {begin} to {end}.")
        return es.search(query = {
            "range":{
                "@timestamp":{
                    "gte": begin,
                    "lt": end,
                }
            }
        })
    
    def analyze(self, s: dict[str, Any], query_info: dict[str,Any]) -> dict[str, Any]:
        r = {}
        r.update(query_info)
        r['num_hits'] = s['hits']['total']['value'] #type: int
        r['scan_len'] = r['scan_end'] - r['scan_begin'] #type: timedelta
        r['allowed_hits'] = r['scan_len'] / self.allowed_threat_interval #type: float
        return r
    
    def trigger(self, analysis: dict[str, Any]) -> bool:
        if analysis['num_hits'] > analysis['allowed_hits']:
            self.log.info(f"Triggering on {analysis['num_hits']}/{analysis['allowed_hits']} hits.")
            return True
        else:
            self.log.info(f"Suppressing {analysis['num_hits']}/{analysis['allowed_hits']} hits.")

        return False
    
    def alert(self, a: dict[str, Any]) -> None:
        to = config("MAILTO")
        subject = f"Alert: {apnumber(a['num_hits'])} threats detected in the last {naturaldelta(a['scan_len'])}"
        contents = f"""
{a['num_hits']} events detected between {a['scan_begin']} and {a['scan_end']}.
"""
        self.log.info(f"Sending email with subject: {subject}")
        smtp.send(to, subject, contents)
        self.log.info(f"Email sent!")

def main():
    alerter = Alerter()
    logging.basicConfig(level=logging.DEBUG)
    while True:
        sleep_until = alerter.loop()
        sleep_len = max(timedelta(seconds=0.1), (sleep_until - datetime.now()))
        logging.debug(f"Sleeping for {sleep_len} (until {sleep_until}).")
        sleep(sleep_len.total_seconds())

if __name__ == "__main__":
    main()
