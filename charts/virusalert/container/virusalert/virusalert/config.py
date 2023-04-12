from dataclasses import dataclass, field
import functools

from datetime import datetime, timedelta
import pytimeparse

import decouple

import yagmail, yagmail.dkim
import elasticsearch

__all__ = ["Config"]

default_subject = "Alert: {info.num_hits:apnumber} threat(s) detected in the last {info.scan_len:naturaldelta}"
default_body = """
{info.num_hits} event(s) detected between {info.scan_begin} and {info.scan_end}.

Threat sources include:
{info.sources_list}
"""

def parse_dt(s: str) -> timedelta:
    return timedelta(seconds=pytimeparse.parse(s))

def config_value(*a, **k):
    return field(default_factory=functools.partial(decouple.config, *a, **k))
def config_secret(*a, **k):
    return field(default_factory=functools.partial(decouple.config, *a, **k), repr=False)

@dataclass
class Config:
    scan_interval: timedelta = config_value("SCAN_INTERVAL", cast=parse_dt)
    scan_window: timedelta = config_value("SCAN_WINDOW", cast=parse_dt)
    alert_interval: timedelta = config_value("ALERT_INTERVAL", cast=parse_dt)
    allowed_threat_interval: timedelta = config_value("ALLOWED_THREAT_INTERVAL", cast=parse_dt)
    # only alert if more threats than 1>allowed_threat_interval

    es_hosts: str = config_value("ES_HOSTS")
    es_user: str = config_value("ES_USER")
    es_password: str = config_secret("ES_PASSWORD")
    @functools.cached_property
    def es(self) -> elasticsearch.Elasticsearch:
        return elasticsearch.Elasticsearch(
            hosts = self.es_hosts,
            http_auth = (self.es_user, self.es_password),
            verify_certs = False,
        )
    
    dkim_domain: str = config_value("DKIM_DOMAIN", default=None)
    dkim_key: str = config_secret("DKIM_KEY", default=None)
    dkim_selector: str = config_value("DKIM_SELECTOR", default=None)
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

    smtp_user: str = config_value("SMTP_USER")
    smtp_password: str = config_secret("SMTP_PASSWORD")
    smtp_host: str = config_value("SMTP_HOST")
    smtp_port: str = config_value("SMTP_PORT", default=None)
    @functools.cached_property
    def smtp(self) -> yagmail.SMTP:
        return yagmail.SMTP(
            user = self.smtp_user,
            password = self.smtp_password,
            host = self.smtp_host,
            port = self.smtp_port,
            dkim = self.dkim,
        )
    
    mail_to: str = config_value("MAIL_TO")
    mail_subject_template: str = config_value("MAIL_SUBJECT", default=default_subject)
    mail_body_template: str = config_value("MAIL_BODY", default=default_body)
