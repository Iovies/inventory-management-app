package com.example.inventory.repository;

import com.example.inventory.model.StockMovement;
import org.springframework.context.annotation.Profile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

@Profile("sqlite")
public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    List<StockMovement> findByProduct_Id(Long productId);
}
