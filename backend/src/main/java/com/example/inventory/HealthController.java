package com.example.inventory;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/")
    public String home() {
        return "Inventory backend is running from Jenkins CI/CD";
    }

    @GetMapping("/health")
    public String health() {
        return "OK - deployed automatically by Jenkins";
    }
    
    @GetMapping("/test")
    public String test() {
        return "Test lab 4";
    }
}