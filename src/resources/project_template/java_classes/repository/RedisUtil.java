

import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.ListOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

public class RedisUtil<T> {

    private RedisTemplate<String, T> redisTemplate;
    private HashOperations<String, Object, T> hashOperation;
    private ListOperations<String, T> listOperation;
    private ValueOperations<String, T> valueOperations;

    private String keyPrefix;

    RedisUtil(String keyPrefix, RedisTemplate<String, T> redisTemplate) {
        this.keyPrefix = keyPrefix == null ? "" : keyPrefix;
        this.redisTemplate = redisTemplate;
        this.hashOperation = this.redisTemplate.opsForHash();
        this.listOperation = this.redisTemplate.opsForList();
        this.valueOperations = this.redisTemplate.opsForValue();
    }

    protected String getFullRedisKey(String redisKey) {
        return this.keyPrefix + redisKey;
    }

    public void deleteAllServiceKeys() {
        this.deleteAllKeysMatchingPattern(this.keyPrefix + ".*");
    }

    /*
     *  General operations
     *  Add others if needed! Reference for all available functions:
     *  https://docs.spring.io/spring-data/redis/docs/current/api/org/springframework/data/redis/core/RedisTemplate.html
     */
    public void setExpire(String redisKey, long timeout, TimeUnit unit) {
        this.redisTemplate.expire(this.getFullRedisKey(redisKey), timeout, unit);
    }

    public boolean hasKey(String redisKey) {
        return this.redisTemplate.hasKey(this.getFullRedisKey(redisKey));
    }

    public void deleteKey(String redisKey) {
        this.redisTemplate.delete(this.getFullRedisKey(redisKey));
    }

    public void deleteAllKeysMatchingPattern(String keyPattern) {
        Set<String> keys = this.redisTemplate.keys(keyPattern);
        this.redisTemplate.delete(keys);
    }


    /*
     *  HashMap operations wrappers
     *  Add others if needed! Reference for all available functions:
     *  https://docs.spring.io/spring-data/redis/docs/current/api/org/springframework/data/redis/core/HashOperations.html
     */
    public void putInMap(String redisKey, Object hashKey, T data) {
        this.hashOperation.put(this.getFullRedisKey(redisKey), hashKey, data);
    }

    public T getMapSingleEntry(String redisKey, Object hashKey) {
        return this.hashOperation.get(this.getFullRedisKey(redisKey), hashKey);
    }

    public Map<Object, T> getMapAllEntries(String redisKey) {
        return this.hashOperation.entries(this.getFullRedisKey(redisKey));
    }


    /*
     *  Direct key-value operations wrappers
     *  Add others if needed! Reference for all available functions:
     *  https://docs.spring.io/spring-data/redis/docs/current/api/org/springframework/data/redis/core/ValueOperations.html
     */
    public void putValue(String redisKey, T value) {
        this.valueOperations.set(this.getFullRedisKey(redisKey), value);
    }

    public void putValueWithExpireTime(String redisKey, T value, Duration expirationDuration) {
        this.valueOperations.set(this.getFullRedisKey(redisKey), value, expirationDuration);
    }

    public T getValue(String redisKey) {
        return this.valueOperations.get(this.getFullRedisKey(redisKey));
    }


    /*
     *  List operations wrappers
     *  Add others if needed! Reference for all available functions:
     *  https://docs.spring.io/spring-data/redis/docs/current/api/org/springframework/data/redis/core/ListOperations.html
     */
    public void setListValueAtIndex(String redisKey, long index, T value) {
        this.listOperation.set(this.getFullRedisKey(redisKey), index, value);
    }

    public T getListValueAtIndex(String redisKey, long index) {
        return this.listOperation.index(this.getFullRedisKey(redisKey), index);
    }

    public Long addListValueAtStart(String redisKey, T value) {
        return this.listOperation.leftPush(this.getFullRedisKey(redisKey), value);
    }

    public T removeListValueAtStart(String redisKey) {
        return this.listOperation.leftPop(this.getFullRedisKey(redisKey));
    }

    public Long addListValueAtEnd(String redisKey, T value) {
        return this.listOperation.rightPush(this.getFullRedisKey(redisKey), value);
    }

    public T removeListValueAtEnd(String redisKey) {
        return this.listOperation.rightPop(this.getFullRedisKey(redisKey));
    }

    public List<T> getListValueInRange(String redisKey, long start, long end) {
        return this.listOperation.range(this.getFullRedisKey(redisKey), start, end);
    }

    public Long getListSize(String redisKey) {
        return this.listOperation.size(this.getFullRedisKey(redisKey));
    }

}