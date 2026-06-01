package com.example.inventory.service;

import com.example.inventory.dto.ProductRequest;
import com.example.inventory.model.Category;
import com.example.inventory.model.Product;
import com.example.inventory.repository.CategoryRepository;
import com.example.inventory.repository.ProductRepository;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.NoSuchElementException;

@Service
public class ProductService {

    private static final int DEFAULT_LOW_STOCK_THRESHOLD = 5;

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;

    public ProductService(ProductRepository productRepository, CategoryRepository categoryRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll()
                .stream()
                .sorted(Comparator.comparing(Product::getId))
                .toList();
    }

    public List<Product> getLowStockProducts() {
        return productRepository.findAll()
                .stream()
                .filter(product -> product.getQuantity() <= getLowStockThreshold(product))
                .sorted(Comparator.comparing(Product::getId))
                .toList();
    }

    public Product getProductById(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Product with id " + id + " was not found"));
    }

    public Product createProduct(ProductRequest request) {
        Product product = new Product();
        applyRequest(product, request);

        return productRepository.save(product);
    }

    public Product updateProduct(Long id, ProductRequest request) {
        Product existingProduct = getProductById(id);
        applyRequest(existingProduct, request);

        return productRepository.save(existingProduct);
    }

    public Product updateQuantity(Long id, Integer quantity) {
        if (quantity == null || quantity < 0) {
            throw new IllegalArgumentException("Quantity must be greater than or equal to 0");
        }

        Product existingProduct = getProductById(id);
        existingProduct.setQuantity(quantity);

        return productRepository.save(existingProduct);
    }

    public void deleteProduct(Long id) {
        if (!productRepository.existsById(id)) {
            throw new NoSuchElementException("Product with id " + id + " was not found");
        }

        productRepository.deleteById(id);
    }

    private void applyRequest(Product product, ProductRequest request) {
        product.setName(request.getName().trim());
        product.setDescription(normalizeOptionalText(request.getDescription()));
        product.setCategory(resolveCategory(request.getCategory()));
        product.setQuantity(request.getQuantity());
        product.setPrice(request.getPrice());
        product.setLowStockThreshold(
                request.getLowStockThreshold() == null ? DEFAULT_LOW_STOCK_THRESHOLD : request.getLowStockThreshold()
        );
    }

    private Category resolveCategory(String categoryName) {
        String normalizedName = categoryName.trim();

        return categoryRepository.findByName(normalizedName)
                .orElseGet(() -> categoryRepository.save(new Category(normalizedName)));
    }

    private String normalizeOptionalText(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        return value.trim();
    }

    private int getLowStockThreshold(Product product) {
        return product.getLowStockThreshold() == null
                ? DEFAULT_LOW_STOCK_THRESHOLD
                : product.getLowStockThreshold();
    }
}
