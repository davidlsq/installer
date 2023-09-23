from passlib.apps import custom_app_context


def hash(value):
    return custom_app_context.hash(value)
