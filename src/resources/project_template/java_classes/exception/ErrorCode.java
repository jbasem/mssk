

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    UNKNOWN_ERROR(HttpStatus.INTERNAL_SERVER_ERROR),
    FORBIDDEN(HttpStatus.FORBIDDEN);

    private HttpStatus httpStatus;

    ErrorCode(HttpStatus httpStatus) {
        this.httpStatus = httpStatus;
    }

    public HttpStatus getHttpStatus() {
        return this.httpStatus;
    }
}
