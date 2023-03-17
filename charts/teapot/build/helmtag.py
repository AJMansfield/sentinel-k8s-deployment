from __future__ import annotations
import yaml
import yaml.emitter
from dataclasses import dataclass
from typing import ClassVar
import logging
logging.basicConfig(level=logging.INFO)

class MarkedString(str):
    """Using a subclass to mark a particular string so the analysis fudger can recognise it."""
    def __repr__(self):
        repr = super().__repr__()
        return f"HelmTagString({repr})"

@dataclass
class HelmTag(yaml.YAMLObject):
    """Represent a Helm template tag that should be emitted unescaped into the yaml stream."""
    yaml_tag: ClassVar[str] = "{{"

    contents: str
    munch_head: bool = False
    munch_tail: bool = False

    @property
    def head_delimiter(self) -> str:
        return '{{-' if self.munch_head else '{{'
    @property
    def tail_delimiter(self) -> str:
        return '-}}' if self.munch_tail else '}}'
    
    def __str__(self) -> str:
        return self.head_delimiter + ' ' + self.contents + ' ' + self.tail_delimiter

    @classmethod
    def to_yaml(cls, dumper: yaml.Dumper, data: HelmTag) -> yaml.Node:
        return yaml.ScalarNode(
            tag = "tag:yaml.org,2002:str", # pretend we're just a string so it doesn't try to add any sort of !!
            value = MarkedString(str(data))
        )

@dataclass
class ScalarAnalysis:
    """Substitute the ScalarAnalysis class with a dataclass for better usability/debuggability."""
    scalar: any
    empty: bool
    multiline: bool
    allow_flow_plain: bool
    allow_block_plain: bool
    allow_single_quoted: bool
    allow_double_quoted: bool
    allow_block: bool

yaml.emitter.ScalarAnalysis = ScalarAnalysis

class FudgedAnalyzer:
    """Descriptor injected into yaml.emitter.Emitter to change the behavior of analyze_scalar"""
    def __init__(self, base_func):
        if hasattr(base_func, 'base_func'):
            self.base_func = base_func.base_func
        else:
            self.base_func = base_func
    def __get__(self, obj, objtype=None):
        bound_analyzer = self.base_func.__get__(obj, objtype)
        def analyzer_function(self, scalar):
            if isinstance(scalar, MarkedString):
                return ScalarAnalysis( # force the helm tags (using marked strings) to be written unquoted
                    scalar,
                    empty = False,
                    multiline = False,
                    allow_flow_plain = True,
                    allow_block_plain = True,
                    allow_single_quoted = False,
                    allow_double_quoted = False,
                    allow_block = False,
                )
            else:
                return bound_analyzer(scalar)
        return analyzer_function.__get__(obj, objtype)

# have to retrieve it via the dict to dodge the descriptor:
yaml.emitter.Emitter.analyze_scalar = FudgedAnalyzer(yaml.emitter.Emitter.__dict__['analyze_scalar'])
