package com.example.inventory.repository;

import com.example.inventory.model.Category;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Repository
@Profile("local")
public class InMemoryCategoryRepository implements CategoryRepository {

    private final Map<Long, Category> categories = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    @Override
    public Optional<Category> findByName(String name) {
        return categories.values()
                .stream()
                .filter(category -> category.getName().equalsIgnoreCase(name))
                .findFirst();
    }

    @Override
    public Category save(Category category) {
        if (category.getId() == null) {
            category.setId(idGenerator.getAndIncrement());
            category.setCreatedAt(LocalDateTime.now());
        }

        categories.put(category.getId(), category);
        return category;
    }
}
