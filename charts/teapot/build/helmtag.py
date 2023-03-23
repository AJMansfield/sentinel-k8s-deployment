from __future__ import annotations
import yaml
import yaml.emitter
from yaml.emitter import Emitter
from dataclasses import dataclass
from typing import ClassVar
import logging
logging.basicConfig(level=logging.INFO)

__all__ = ['HelmTag', 'EnableHelmTag']

"""
Provides a way to emit raw unescaped helm template tags using the default
python yaml emitter.
To use this:
- place a `HelmTag` instance into the object tree
- enter an `EnableHelmTag` context
- write the object tree out using `yaml.dump` (NOT `yaml.safe_dump`)
"""

@dataclass
class HelmTag(yaml.YAMLObject):
    """A helm tag to emit unescaped into yaml."""
    yaml_tag: ClassVar[str] = "{{"

    contents: str
    munch_head: bool = None
    munch_tail: bool = None

    def __post_init__(self):
        if self.munch_head is None:
            if self.contents.startswith('{{-'):
                self.munch_head = True
            elif self.contents.startswith('{{'):
                self.munch_head = False
            else:
                raise ValueError("cannot determine munch_head")
            self.contents = self.contents.removeprefix(self.head_delimiter).lstrip()
        if self.munch_tail is None:
            if self.contents.endswith('-}}'):
                self.munch_tail = True
            elif self.contents.endswith('}}'):
                self.munch_tail = False
            else:
                raise ValueError("cannot determine munch_tail")
            self.contents = self.contents.removesuffix(self.tail_delimiter).rstrip()
    
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
            tag = "tag:yaml.org,2002:str", # avoid the "!!" by pretending we're just a string
            value = MarkedString(str(data)), # fudged analyzer below
        )

class MarkedString(str):
    """Using a subclass to mark a particular string so the analysis fudger can recognise it."""
    def __repr__(self):
        repr = super().__repr__()
        return f"HelmTagString({repr})"

if True:
    from yaml.emitter import ScalarAnalysis
else:
    @dataclass
    class ScalarAnalysis:
        """Class to substitute for `yaml.emitter.ScalarAnalysis`.
        This class is exactly the same as the one it replaces, save for the
        addition of type annotations, a `repr` implementation, and other
        dataclass niceties.
        """
        scalar: any
        empty: bool
        multiline: bool
        allow_flow_plain: bool
        allow_block_plain: bool
        allow_single_quoted: bool
        allow_double_quoted: bool
        allow_block: bool

    yaml.emitter.ScalarAnalysis = ScalarAnalysis
    

class EnableHelmTag:
    """Context manager and function descriptor for patching `yaml.emitter.Emitter.analyze_scalar`.
    While active, this will fudge any analyses of HelmTag's internal marked strings
    to force the yaml emitter to emit them directly without any escaping.
    """
    def __enter__(self):
        # have to access via __dict__ to dodge function descriptor binding
        self.base_func = Emitter.__dict__['analyze_scalar']
        Emitter.__dict__['analyze_scalar'] = self
        return self
    def __exit__(self, typ, val, tb):
        assert Emitter.__dict__['analyze_scalar'] is self, "unknown yaml.emitter.Emitter.analyze_scalar -- exit patches in reverse order!"
        Emitter.__dict__['analyze_scalar'] = self.base_func
        del self.base_func

    def __get__(self, obj, objtype=None):
        assert hasattr(self, 'base_func'), "patch not currently applied -- enter the EnableHelmTag context first!"
        bound_analyzer = self.base_func.__get__(obj, objtype) # bind the base function's `self`
        def analyzer_function(self, scalar):
            if isinstance(scalar, MarkedString):
                return ScalarAnalysis( # force unescaped output
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
        return analyzer_function.__get__(obj, objtype) # bind the replacement function's `self`

