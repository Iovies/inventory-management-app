package com.example.inventory.repository;

import com.example.inventory.model.Product;
import org.springframework.context.annotation.Profile;
import org.springframework.data.jpa.repository.JpaRepository;

@Profile("sqlite")
public interface JpaProductRepository extends ProductRepository, JpaRepository<Product, Long> {
}
