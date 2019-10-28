

import com.rollbar.notifier.Rollbar;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;


@ControllerAdvice
public class ExceptionHandlingControllerAdvice {
    // General Exception
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ExceptionResponse> generalException(Exception exception) {
        exception.printStackTrace();
        ExceptionResponse response = new ExceptionResponse();
        response.setStatus(ErrorCode.UNKNOWN_ERROR.getHttpStatus().value());
        response.setError(ErrorCode.UNKNOWN_ERROR.name());
        response.setMessage(exception.getMessage());
        return new ResponseEntity<>(response, ErrorCode.UNKNOWN_ERROR.getHttpStatus());
    }

    // General Authentication Exception
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ExceptionResponse> authenticationException(AuthenticationException exception) {
        exception.printStackTrace();
        ExceptionResponse response = new ExceptionResponse();
        response.setStatus(ErrorCode.FORBIDDEN.getHttpStatus().value());
        response.setError(ErrorCode.FORBIDDEN.name());
        response.setMessage(exception.getMessage());
        return new ResponseEntity<>(response, ErrorCode.FORBIDDEN.getHttpStatus());
    }

}
