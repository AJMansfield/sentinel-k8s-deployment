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

default_subject = "Alert: {info.num_hits:apnumber} threat(s) detected in the last {info.scan_len:naturaldelta}"
default_body = """
{info.num_hits} event(s) detected between {info.scan_begin} and {info.scan_end}.

Threat sources include:
{info.sources_list}
"""

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

@dataclass
class Config:
    scan_interval: timedelta = config("SCAN_INTERVAL", cast=parse_dt)
    scan_window: timedelta = config("SCAN_WINDOW", cast=parse_dt)
    alert_interval: timedelta = config("ALERT_INTERVAL", cast=parse_dt)
    allowed_threat_interval: timedelta = config("ALLOWED_THREAT_INTERVAL", cast=parse_dt)
    # only alert if more threats than 1>allowed_threat_interval

    es_hosts: str = config("ES_HOSTS")
    es_user: str = config("ES_USER")
    es_password: str = field(default=config("ES_PASSWORD"), repr=False)
    @functools.cached_property
    def es(self) -> elasticsearch.Elasticsearch:
        return elasticsearch.Elasticsearch(
            hosts = self.es_hosts,
            http_auth = (self.es_user, self.es_password),
            verify_certs = False,
        )
    
    dkim_domain: str = config("DKIM_DOMAIN", default=None)
    dkim_key: str = field(default=config("DKIM_KEY", default=None), repr=False)
    dkim_selector: str = config("DKIM_SELECTOR", default=None)
    @functools.cached_property
    def dkim(self) -> yagmail.dkim.DKIM | None:
        try:
            return yagmail.dkim.DKIM(
                domain = self.dkim_domain.encode('ascii'),
                private_key = self.dkim_key.encode('ascii'),
                selector = self.dkim_selector.encode('ascii'),
                include_headers = None,
            )
        except AttributeError as e:
            # AttributeError("'NoneType' object has no attribute 'encode'")
            if e.obj is None and e.name == 'encode':
                return None
            else:
                raise e

    smtp_user: str = config("SMTP_USER")
    smtp_password: str = field(default=config("SMTP_PASSWORD"), repr=False)
    smtp_host: str = config("SMTP_HOST")
    smtp_port: str = config("SMTP_PORT", default=None)
    @functools.cached_property
    def smtp(self) -> yagmail.SMTP:
        return yagmail.SMTP(
            user = self.smtp_user,
            password = self.smtp_password,
            host = self.smtp_host,
            port = self.smtp_port,
            dkim = self.dkim,
        )
    
    mail_to: str = config("MAIL_TO")
    mail_subject_template: str = config("MAIL_SUBJECT", default = default_subject)
    mail_body_template: str = config("MAIL_BODY", default= default_body)


@dataclass
class Alerter:
    
    last_scan_time: datetime = field(default_factory=datetime.now)
    next_scan_time: datetime = field(default_factory=datetime.now)
    last_alert_time: datetime = field(default_factory=datetime.now)
    next_alert_time: datetime = field(default_factory=datetime.now)

    config: Config = field(default_factory=Config)
    log: logging.Logger = field(default=logging.getLogger("alerter"), repr=False)
    def __str__(self) -> str:
        return f"LS={self.last_scan_time} NS={self.next_scan_time} LA={self.last_alert_time} NA={self.next_alert_time}"

    def loop(self, now: datetime = None) -> datetime:
        self.log.info(f"begin loop: {self!s}")
        if now is None: now = datetime.now()

        alert_cooldown = now >= self.next_alert_time
        scan_cooldown = now >= self.next_scan_time

        if alert_cooldown and scan_cooldown:
            info = SimpleNamespace()

            info.scan_begin = min(self.last_scan_time, now - self.config.scan_window)
            info.scan_end = now

            info.scan = self.scan(begin=info.scan_begin, end=info.scan_end)
            self.last_scan_time = now
            self.next_scan_time = now + self.config.scan_interval

            self.analyze(info)

            self.log.info(f"{info.scan_len=!s}")
            self.log.info(f"{info.num_hits=}")
            self.log.info(f"{info.allowed_hits=}")

            trigger = self.trigger(info)

            if trigger:
                self.alert(info)
                self.last_alert_time = now
                self.next_alert_time = now + self.config.alert_interval

        
        may_sleep_until = max(self.next_alert_time, self.next_scan_time)

        self.log.info(f"end loop: {self!s}")
        return may_sleep_until

    def scan(self, begin: datetime = None, end: datetime = None) -> dict[str,Any]:
        self.log.info(f"Scanning from {begin} to {end}.")
        return self.config.es.search(query = {
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
        info.allowed_hits = info.scan_len / self.config.allowed_threat_interval #type: float
        return info
    
    def trigger(self, info: SimpleNamespace) -> bool:
        if info.num_hits > info.allowed_hits:
            self.log.info(f"Triggering.")
            return True
        else:
            self.log.info(f"Suppressing.")

        return False
    
    def alert(self, info: SimpleNamespace) -> None:
        to = self.config.mail_to
        subject = humanize_formatter.format(self.config.mail_subject_template, info=info)
        body = humanize_formatter.format(self.config.mail_body_template, info=info)
        self.log.info(f"Sending email!")
        self.log.info(f"TO: {to}")
        self.log.info(f"SUBJECT: {subject}")
        self.log.info(f"BODY: {body}")
        # self.config.smtp.send(to, subject, contents)
        self.log.info(f"Email sent!")


def main():
    logging.basicConfig(level=logging.INFO)
    logging.getLogger('elasticsearch').setLevel(logging.WARNING)
    import urllib3
    urllib3.disable_warnings()
    logging.getLogger('urllib3.connectionpool').setLevel(logging.WARNING)

    config = Config()
    alerter = Alerter(config=config)
    while True:
        sleep_until = alerter.loop()
        sleep_len = max(timedelta(seconds=0), (sleep_until - datetime.now()))
        logging.info(f"Sleeping for {sleep_len} (until {sleep_until}).")
        sleep(sleep_len.total_seconds())

if __name__ == "__main__":
    main()
