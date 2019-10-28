

import java.net.URI;
import java.util.Optional;
import javax.naming.ServiceUnavailableException;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.cloud.client.discovery.DiscoveryClient;


@Configuration
public class ServiceDiscoveryUtils {

    @Autowired
    private DiscoveryClient discoveryClient;

    public Optional<URI> serviceBaseUrl(String serviceName) {
        return discoveryClient.getInstances(serviceName)
          .stream()
          .findFirst()
          .map(si -> si.getUri());
    }

    public URI serviceEndpoint(String serviceName, String endpointPath) throws ServiceUnavailableException {
        return serviceBaseUrl(serviceName)
            .map(s -> s.resolve("/" + serviceName + "/" + endpointPath))
            .orElseThrow(ServiceUnavailableException::new);
    }
}
