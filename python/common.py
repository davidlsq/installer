import yaml


def read_yaml(path):
    with path.open("r") as path_stream:
        return yaml.safe_load(path_stream)


def write_yaml(value, path):
    with path.open("w") as path_stream:
        yaml.dump(value, path_stream, sort_keys=False)
