

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

/*
 * This is not used for now as we don't want DTOs at the moment, but can be used in future.
 * Remember: DTOs needs to also copy validations (so that the can be validated in the Request).
 */
@Component
public class GenericMapper{

    @Autowired
    private ModelMapper modelMapper;

    /**
     *
     * @param source                source object (<code><S></code>) to be mapped
     * @param destinationClass      class of destination (<code><D></code>)
     * @param <S>                   source type
     * @param <D>                   destination type
     * @return                      converted object (<code><D></code> type)
     */
    public <S, D> D map(final S source, Class<D> destinationClass) {
        return modelMapper.map(source, destinationClass);
    }

    /**
     *
     * @param sourceList            list of source objects (<code><S></code>) to be mapped
     * @param destinationClass      class of destination (<code><D></code>)
     * @param <S>                   source type
     * @param <D>                   destination type
     * @return                      list of converted objects (<code><D></code> type)
     */
    public <S, D> List<D> mapAll(Collection<S> sourceList, Class<D> destinationClass){
        if(sourceList == null || sourceList.isEmpty()) {
            return new ArrayList<D>();
        }
        return sourceList.stream().map(dto -> this.map(dto, destinationClass)).collect(Collectors.toList());
    }
}
