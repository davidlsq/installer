#!/usr/bin/env python

import json
import os
from subprocess import check_output

import click
import yaml


@click.command()
@click.option("--organization", type=str, required=True)
@click.option("--output", type=str, required=True)
def main(organization, output):
    session_id = check_output(["bw", "unlock", "--raw"]).decode()

    organizations = check_output(
        ["bw", "list", "organizations"], env={**os.environ, "BW_SESSION": session_id}
    )
    organizations = json.loads(organizations)
    organizations = {
        organization["name"]: organization["id"] for organization in organizations
    }

    organization_id = organizations[organization]

    items = check_output(
        [
            "bw",
            "export",
            "--format",
            "json",
            "--organizationid",
            organization_id,
            "--raw",
        ],
        env={**os.environ, "BW_SESSION": session_id},
    )
    items = json.loads(items)["items"]

    variables = {}
    for item in items:
        if _is_importable(item):
            variables.update(_get_variables(item))

    with open(output, "w") as output_stream:
        yaml.dump(variables, output_stream)


def _is_importable(item):
    return any(
        [
            field["name"] == "import" and field["value"] == "true"
            for field in item["fields"]
        ]
    )


def _get_variables(item):
    variables = {}
    item_name = item["name"]
    if item["login"]["username"] is not None:
        variables[f"{item_name}_username"] = item["login"]["username"]
    if item["login"]["password"] is not None:
        variables[f"{item_name}_password"] = item["login"]["password"]
    for field in item["fields"]:
        if field["name"] != "import":
            field_name = field["name"]
            variables[f"{item_name}_{field_name}"] = field["value"]
    variables = {f"bitwarden_{key}": value for (key, value) in variables.items()}
    return variables


if __name__ == "__main__":
    main()
