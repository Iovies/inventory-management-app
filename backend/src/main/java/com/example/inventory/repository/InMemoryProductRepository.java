package com.example.inventory.repository;

import com.example.inventory.model.Product;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Repository
@Profile("local")
public class InMemoryProductRepository implements ProductRepository {

    private final Map<Long, Product> products = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    @Override
    public List<Product> findAll() {
        return products.values()
                .stream()
                .sorted(Comparator.comparing(Product::getId))
                .toList();
    }

    @Override
    public Optional<Product> findById(Long id) {
        return Optional.ofNullable(products.get(id));
    }

    @Override
    public Product save(Product product) {
        LocalDateTime now = LocalDateTime.now();

        if (product.getId() == null) {
            product.setId(idGenerator.getAndIncrement());
            product.setCreatedAt(now);
        }

        product.setUpdatedAt(now);
        products.put(product.getId(), product);
        return product;
    }

    @Override
    public boolean existsById(Long id) {
        return products.containsKey(id);
    }

    @Override
    public void deleteById(Long id) {
        products.remove(id);
    }
}
