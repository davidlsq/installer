from os.path import basename, dirname

from common import chmod
from jinja2 import Environment, FileSystemLoader, StrictUndefined


def render(src, dest, variables, mode=None):
    loader = FileSystemLoader(searchpath=dirname(src))
    env = Environment(loader=loader, undefined=StrictUndefined)
    template = env.get_template(basename(src))
    output = template.render(**variables)
    with dest.open("w") as dest_stream:
        dest_stream.write(output)
    if mode is not None:
        chmod(dest, mode)
