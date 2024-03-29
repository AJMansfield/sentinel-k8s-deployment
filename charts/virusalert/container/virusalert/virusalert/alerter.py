from dataclasses import dataclass, field
from datetime import datetime, timedelta

from types import SimpleNamespace
from typing import Any

from virusalert.config import Config
from virusalert.humanize import humanize_formatter
from natsort import natsorted
import dns.exception, dns.reversename, dns.name, dns.resolver

import logging

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
    
    def updateConfig(self, new_config: Config):
        self.next_alert_time = self.next_alert_time - self.config.alert_interval + new_config.alert_interval
        self.next_scan_time = self.next_scan_time - self.config.scan_interval + new_config.scan_interval

        self.config = new_config

    def loop(self, now: datetime = None) -> datetime:
        self.log.debug(f"begin loop: {self!s}")
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
            self.log.info(f"{info.score=}")
            self.log.info(f"{info.allowed_score=}")

            trigger = self.trigger(info)

            if trigger:
                self.alert(info)
                self.last_alert_time = now
                self.next_alert_time = now + self.config.alert_interval

        
        may_sleep_until = max(self.next_alert_time, self.next_scan_time)

        self.log.debug(f"end loop: {self!s}")
        return may_sleep_until

    def scan(self, begin: datetime = None, end: datetime = None) -> dict[str,Any]:
        self.log.info(f"Scanning from {begin} to {end}.")

        query_must = self.config.query_must or []
        query_must_not = self.config.query_must_not or []
        score_funcs = self.config.score_funcs or []
        
        return self.config.es.search(
            size = 10000,
            query = { "function_score": {
                "query": { "bool": {
                    "must": [
                        { "range": { "@timestamp": { "gte": begin, "lt": end } } },
                        *query_must
                    ], 
                    "must_not": query_must_not,
                }},
                "functions": score_funcs
            }},
            aggregations = {"score":{"sum":{"script":{"source":"_score"}}}}
            )
    
    def analyze(self, info: SimpleNamespace) -> SimpleNamespace:
        info.num_hits = info.scan['hits']['total']['value'] #type: int
        info.score = info.scan['aggregations']['score']['value'] #type: float
        info.scan_len = info.scan_end - info.scan_begin #type: timedelta
        info.allowed_score = info.scan_len / self.config.allowed_threat_interval #type: float
        self.collect_sources(info)
        return info
    
    def collect_sources(self, info: SimpleNamespace) -> SimpleNamespace:
        sources = set()
        hits = info.scan['hits']['hits']

        field_names = [
            'source.ip',
            'client.ip',
            'related.ip',
            'server.ip',
            'destination.ip',
            'path',
            'host.name',
            'samba.src_host',
            'samba.src_ip',
            'samba.src_user',
            'src_ip',
            'tpot.src_ip',
        ]
        def get_dotted(source:dict, dotted_key:str, default=None):
            for element in dotted_key.split('.'):
                try:
                    source = source[element]
                except (KeyError, TypeError):
                    return default
            return source
        
        def classify_source(source:str) -> str:
            if source.startswith('/'):
                return "File"
            elif source.count(':') >= 2:
                return "IPv6"
            elif source.count('.') == 3:
                return "IPv4"
            else:
                return "Host"
        
        def get_extra_data(source_class:str, value:str) -> str | None:
            if source_class in ("IPv4", "IPv6"):
                try:
                    addr = dns.reversename.from_address(value)
                    answer = dns.resolver.query(addr, "PTR")
                    name = str(answer[0])
                    name = name.removesuffix('.')
                    return name
                except (dns.exception.DNSException, IndexError):
                    pass
            return None
        
        def format_source(field:str, value:str) -> str:
            source_class = classify_source(value)
            extra_data = get_extra_data(source_class, value)
            if extra_data:
                return f"{source_class}: {value} ({extra_data})"
            else:
                return f"{source_class}: {value}"
        
        for hit in hits:
            hit = hit['_source']
            for field in field_names:
                value = get_dotted(hit, field)
                if value is None:
                    pass
                elif isinstance(value, str):
                    self.log.debug(f"added source {value}")
                    sources.add(format_source(field, value))
                elif isinstance(value, list):
                    self.log.debug(f"added sources {value}")
                    sources.update((format_source(field, v) for v in value))
                else:
                    self.log.warning(f"unknown type for {field}")
        
        info.sources = sources
        if sources:
            info.sources_list = '\n'.join(f"- {src}" for src in natsorted(list(sources)))
        else:
            info.sources_list = "(no specific sources identified)"
        return info
    
    def trigger(self, info: SimpleNamespace) -> bool:
        if info.score > info.allowed_score:
            self.log.info(f"Threshold met, triggering.")
            return True
        else:
            self.log.info(f"Threshold not met, suppressing.")

        return False
    
    def alert(self, info: SimpleNamespace) -> None:
        to = self.config.mail_to
        subject = humanize_formatter.format(self.config.mail_subject_template, info=info)
        body = humanize_formatter.format(self.config.mail_body_template, info=info)
        self.log.info(f"Sending email!")
        self.log.info(f"TO: {to}")
        self.log.info(f"SUBJECT: {subject}")
        self.log.info(f"BODY: {body}")
        self.config.smtp.send(to, subject, body)
        self.log.info(f"Email sent!")
