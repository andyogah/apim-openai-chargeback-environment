import azure.functions as func

from process_logs import main as process_logs_handler


app = func.FunctionApp()


@app.route(route="log", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def process_logs(req: func.HttpRequest) -> func.HttpResponse:
    return process_logs_handler(req)