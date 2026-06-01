package com.example.inventory.repository;

import com.example.inventory.model.Category;
import org.springframework.data.repository.NoRepositoryBean;

import java.util.Optional;

@NoRepositoryBean
public interface CategoryRepository {

    Optional<Category> findByName(String name);

    Category save(Category category);
}
