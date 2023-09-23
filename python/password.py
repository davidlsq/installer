import hashlib

from passlib.apps import custom_app_context


def hash(value):
    return custom_app_context.hash(value)


def sha256(value):
    return hashlib.sha256(value.encode()).hexdigest()
