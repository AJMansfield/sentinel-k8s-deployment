from __future__ import annotations
import yagmail
import yagmail.dkim
import elasticsearch
from decouple import config
import threading
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from time import sleep
from typing import Any, Callable
import logging
import humanize
import pytimeparse
from types import SimpleNamespace
import functools
import string
import re

class HumanizeFormatter(string.Formatter):
    def __init__(self, *a, **k) -> None:
        super().__init__(*a, **k)
        self.converters = {
            name: getattr(humanize, name) for name in dir(humanize) if callable(getattr(humanize, name, None))
        }
        self.converter_args_re = re.compile( r'([^(]*)(?:\(([^)]*)\))?' ) # matches "conv_name(conv_args)"
    
    def format_field(self, value: Any, format_spec: str) -> Any:
        if m := self.converter_args_re.match(format_spec):
            conv_name = m[1]
            conv_args = m[2]
            if conv := self.converters.get(conv_name):
                if conv_args:
                    args = eval(f"_({conv_args})", {'_': SimpleNamespace}, {})
                    conv = functools.partial(conv, **args.__dict__)
                value = conv(value)
            return super().format_field(value, "")
        return super().format_field(value, format_spec)

humanize_formatter = HumanizeFormatter()

def parse_dt(s: str) -> timedelta:
    return timedelta(seconds=pytimeparse.parse(s))

es = elasticsearch.Elasticsearch(
    hosts = config("ES_HOSTS"),
    http_auth = (config("ES_USER"), config("ES_PASSWORD")),
    verify_certs = False,
)

if any(config(param, default=None) for param in ("DKIM_DOMAIN", "DKIM_KEY", "DKIM_SELECTOR")):
    dkim = yagmail.dkim.DKIM(
        domain = config("DKIM_DOMAIN").encode('ascii'),
        private_key = config("DKIM_KEY").encode('ascii'),
        include_headers = None,
        selector = config("DKIM_SELECTOR").encode('ascii'),
    )
else:
    dkim = None

smtp = yagmail.SMTP(
    user = config("SMTP_USER"),
    password = config("SMTP_PASSWORD"),
    host = config("SMTP_HOST"),
    port = config("SMTP_PORT", default=None),
    # dkim = dkim,
)

mail_to = config("MAIL_TO")
mail_subject = "Alert: {info.num_hits:apnumber} threats detected in the last {info.scan_len:naturaldelta}"
mail_body = """
{info.num_hits} events detected between {info.scan_begin} and {info.scan_end}.
"""

@dataclass
class Alerter:
    scan_interval: timedelta = config("SCAN_INTERVAL", cast=parse_dt)
    scan_window: timedelta = config("SCAN_WINDOW", cast=parse_dt)
    alert_interval: timedelta = config("ALERT_INTERVAL", cast=parse_dt)
    allowed_threat_interval: timedelta = config("ALLOWED_THREAT_INTERVAL", cast=parse_dt)
    # only alert if more threats than 1>allowed_threat_interval
    
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
            info = SimpleNamespace()

            info.scan_begin = min(self.last_scan_time, now - self.scan_window)
            info.scan_end = now

            info.scan = self.scan(begin=info.scan_begin, end=info.scan_end)
            self.last_scan_time = now
            self.next_scan_time = now + self.scan_interval

            self.analyze(info)

            trigger = self.trigger(info)

            if trigger:
                self.alert(info)
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
    
    def analyze(self, info: SimpleNamespace) -> SimpleNamespace:
        info.num_hits = info.scan['hits']['total']['value'] #type: int
        info.scan_len = info.scan_end - info.scan_begin #type: timedelta
        info.allowed_hits = info.scan_len / self.allowed_threat_interval #type: float
        return info
    
    def trigger(self, info: SimpleNamespace) -> bool:
        if info.num_hits > info.allowed_hits:
            self.log.info(f"Triggering on {info.num_hits}/{info.allowed_hits} hits.")
            return True
        else:
            self.log.info(f"Suppressing {info.num_hits}/{info.allowed_hits} hits.")

        return False
    
    def alert(self, info: SimpleNamespace) -> None:
        to = mail_to
        subject = humanize_formatter.format(mail_subject, info=info)
        contents = humanize_formatter.format(mail_body, info=info)
        self.log.info(f"Sending email with subject: {subject}")
        smtp.send(to, subject, contents)
        self.log.info(f"Email sent!")

def main():
    alerter = Alerter()
    logging.basicConfig(level=logging.INFO)
    while True:
        sleep_until = alerter.loop()
        sleep_len = max(timedelta(seconds=0), (sleep_until - datetime.now()))
        logging.info(f"Sleeping for {sleep_len} (until {sleep_until}).")
        sleep(sleep_len.total_seconds())

if __name__ == "__main__":
    main()
