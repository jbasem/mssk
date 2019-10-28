

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

@Configuration
public class CustomBeans {

    @Autowired
    private Environment environment;

    @Bean
    public ModelMapper modelMapper() {
        return new ModelMapper();
    }
}
