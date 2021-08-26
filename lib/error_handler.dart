import 'src/pdefault_error_msg_io.dart'
    if (dart.library.html) 'src/pdefault_error_msg_web.dart'
    as _pdefault_err_msg;

import 'src/perror_handler.dart' as _perr_handler;

const catchIt = _perr_handler.catchIt;
const defaultErrorMessageHandler = _pdefault_err_msg.defaultErrorMessageHandler;
const initErrorMessages = _perr_handler.initErrorMessages;
