from __future__ import annotations
from dataclasses import dataclass, field
import functools
from typing import TypeVar, Generic, Callable

from datetime import timedelta
import pytimeparse

import decouple
import yagmail, yagmail.dkim
import elasticsearch
import ssl
import yaml

__all__ = ["Config"]

def parse_dt(s: str) -> timedelta:
    return timedelta(seconds=pytimeparse.parse(s))

class Missing(object):
    """
    Class to represent missing value.
    """
    pass
MISSING = Missing()
class MissingConfigError(Exception):
    pass

T = TypeVar('T')
@dataclass
class ConfigFactory(Generic[T]):
    var: str = ''
    path: str = ''
    default: T | Missing = MISSING
    cast: Callable[[str],T] = lambda x: x

    def decouple_strategy(self) -> T | Missing:
        try:
            return decouple.config(self.var, cast=self.cast)
        except decouple.UndefinedValueError:
            return MISSING
    def kuberfile_strategy(self) -> T | Missing:
        try:
            with open(self.path, 'r') as f:
                value = f.read()
        except FileNotFoundError:
            return MISSING
        return self.cast(value)
    def default_strategy(self) -> T | Missing:
        return self.default
    
    def __call__(self) -> T:
        strategies = [
            self.kuberfile_strategy,
            self.decouple_strategy,
            self.default_strategy,
        ]
        for strategy in strategies:
            result = strategy()
            if result is not MISSING:
                return result
        else:
            raise MissingConfigError(f"cannot find config with {self.var=}, {self.path=}")

def config_value(*a, **k):
    return field(default_factory=ConfigFactory(*a, **k))
def config_secret(*a, **k):
    return field(default_factory=ConfigFactory(*a, **k), repr=False)



@dataclass
class Config:
    scan_interval: timedelta = config_value("SCAN_INTERVAL", "alert/scan_interval", cast=parse_dt)
    scan_window: timedelta = config_value("SCAN_WINDOW", "alert/scan_window", cast=parse_dt)
    alert_interval: timedelta = config_value("ALERT_INTERVAL", "alert/alert_interval", cast=parse_dt)
    allowed_threat_interval: timedelta = config_value("ALLOWED_THREAT_INTERVAL", "alert/allowed_threat_interval", cast=parse_dt)
    # only alert if more threats than 1>allowed_threat_interval
    exclude_filters: list[dict] = config_value("EXCLUDE_FILTERS", "alert/exclude_filters", default=None, cast=yaml.safe_load)
    score_funcs: list[dict] = config_value("SCORE_FUNCS", "alert/score_funcs", default=None, cast=yaml.safe_load)

    es_hosts: str = config_value("ES_HOSTS", "elastic/hosts")
    es_user: str = config_value("ES_USER", "elastic/user")
    es_password: str = config_secret("ES_PASSWORD", "elastic/password")
    es_ca_path: str = config_value("ES_CA_PATH", "elastic/ca_path", default='/etc/elastic/elasticsearch/certs/ca.crt')
    @functools.cached_property
    def es(self) -> elasticsearch.Elasticsearch:
        return elasticsearch.Elasticsearch(
            hosts = self.es_hosts,
            http_auth = (self.es_user, self.es_password),
            ca_certs = self.es_ca_path,
        )
    
    dkim_domain: str = config_value("DKIM_DOMAIN", "dkim/domain", default=None)
    dkim_key: str = config_secret("DKIM_KEY", "dkim/key", default=None)
    dkim_selector: str = config_value("DKIM_SELECTOR", "dkim/selector", default=None)
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

    smtp_user: str = config_value("SMTP_USER", "smtp/username")
    smtp_password: str = config_secret("SMTP_PASSWORD", "smtp/password")
    smtp_host: str = config_value("SMTP_HOST", "smtp/hostname")
    smtp_port: str = config_value("SMTP_PORT", "smtp/port", default=None)
    @functools.cached_property
    def smtp(self) -> yagmail.SMTP:
        return yagmail.SMTP(
            user = self.smtp_user,
            password = self.smtp_password,
            host = self.smtp_host,
            port = self.smtp_port,
            dkim = self.dkim,
        )
    
    mail_to: str = config_value("MAIL_TO", "mail/to")
    mail_subject_template: str = config_value("MAIL_SUBJECT", "mail/subject")
    mail_body_template: str = config_value("MAIL_BODY", "mail/body")
