from flask import Flask
from helper.error import (
    errors_bp,
    bad_request,
    unauthorized,
    forbidden,
    page_not_found,
    method_not_allowed,
    request_timeout,
    too_many_requests,
    internal_server_error,
)


def register_error_handlers(app:Flask, testing=False):

    app.register_blueprint(errors_bp, url_prefix="/")
    app.register_error_handler(400, bad_request)
    app.register_error_handler(401, unauthorized)
    app.register_error_handler(403, forbidden)
    app.register_error_handler(404, page_not_found)
    app.register_error_handler(405, method_not_allowed)
    app.register_error_handler(408, request_timeout)
    app.register_error_handler(429, too_many_requests)
    app.register_error_handler(500, internal_server_error)

    return app