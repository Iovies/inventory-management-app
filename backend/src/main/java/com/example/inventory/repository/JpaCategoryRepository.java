package com.example.inventory.repository;

import com.example.inventory.model.Category;
import org.springframework.context.annotation.Profile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

@Profile("sqlite")
public interface JpaCategoryRepository extends CategoryRepository, JpaRepository<Category, Long> {

    Optional<Category> findByName(String name);
}
