import yaml


def read_yaml(path):
    with open(path, "r") as path_stream:
        return yaml.safe_load(path_stream)


def write_yaml(value, path):
    with open(path, "w") as path_stream:
        yaml.dump(value, path_stream, sort_keys=False)
