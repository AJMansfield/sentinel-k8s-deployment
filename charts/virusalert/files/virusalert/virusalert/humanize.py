import string
import humanize
import re
import functools
from types import SimpleNamespace
from typing import Any

__all__ = ["HumanizeFormatter, humanize_formatter"]

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