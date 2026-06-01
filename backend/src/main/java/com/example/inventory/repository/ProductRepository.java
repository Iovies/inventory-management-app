package com.example.inventory.repository;

import com.example.inventory.model.Product;
import org.springframework.data.repository.NoRepositoryBean;

import java.util.List;
import java.util.Optional;

@NoRepositoryBean
public interface ProductRepository {

    List<Product> findAll();

    Optional<Product> findById(Long id);

    Product save(Product product);

    boolean existsById(Long id);

    void deleteById(Long id);
}
