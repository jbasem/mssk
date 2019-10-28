

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ExceptionResponse implements Serializable {

    private LocalDateTime timestamp;
    private int status;
    private String error;
    private String message;
    private List<ErrorDetail> details = new ArrayList<>();

    public ExceptionResponse() {
        this.timestamp = LocalDateTime.now();
    }

    public ExceptionResponse(int status, String error, String message, List<ErrorDetail> details) {
        this();
        this.status = status;
        this.error = error;
        this.message = message;
        this.details = details;
    }

    /**
     * Auto generated
     */

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public List<ErrorDetail> getDetails() {
        return details;
    }

    public void setDetails(List<ErrorDetail> details) {
        this.details = details;
    }

    @Override
    public String toString() {
        return "ExceptionResponse{" +
                "timestamp=" + timestamp +
                ", status='" + status + '\'' +
                ", error='" + error + '\'' +
                ", message='" + message + '\'' +
                ", details=" + details +
                '}';
    }
}
