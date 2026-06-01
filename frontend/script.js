const DEFAULT_API_URL = "/api/products";

const apiUrlInput = document.getElementById("apiUrl");
const productForm = document.getElementById("productForm");
const productIdInput = document.getElementById("productId");
const formTitle = document.getElementById("formTitle");
const submitButton = document.getElementById("submitButton");
const cancelEditButton = document.getElementById("cancelEdit");
const refreshButton = document.getElementById("refreshButton");
const message = document.getElementById("message");
const productsTableBody = document.getElementById("productsTableBody");
const lowStockList = document.getElementById("lowStockList");

let products = [];

function getApiUrl() {
    return (apiUrlInput.value.trim() || DEFAULT_API_URL).replace(/\/$/, "");
}

function showMessage(text, isError = false) {
    message.textContent = text;
    message.classList.toggle("error", isError);
}

async function apiRequest(path = "", options = {}) {
    const response = await fetch(`${getApiUrl()}${path}`, {
        ...options,
        headers: {
            "Content-Type": "application/json",
            ...(options.headers || {})
        }
    });

    if (response.status === 204) {
        return null;
    }

    const data = await response.json().catch(() => null);

    if (!response.ok) {
        throw new Error(data?.message || "Cererea catre backend a esuat.");
    }

    return data;
}

async function loadProducts() {
    try {
        showMessage("");
        const [allProducts, lowStockProducts] = await Promise.all([
            apiRequest(),
            apiRequest("/low-stock")
        ]);

        products = allProducts;
        renderProducts(allProducts);
        renderLowStock(lowStockProducts);
    } catch (error) {
        showMessage(error.message, true);
    }
}

function renderProducts(items) {
    productsTableBody.innerHTML = "";

    if (items.length === 0) {
        const row = document.createElement("tr");
        row.innerHTML = `<td colspan="9" class="empty-state">Nu exista produse.</td>`;
        productsTableBody.appendChild(row);
        return;
    }

    items.forEach((product) => {
        const row = document.createElement("tr");
        row.innerHTML = `
            <td>${product.id}</td>
            <td>${escapeHtml(product.name)}</td>
            <td>${escapeHtml(product.category || "-")}</td>
            <td>${escapeHtml(product.description || "-")}</td>
            <td>
                <div class="quantity-cell">
                    <input type="number" min="0" step="1" value="${product.quantity}" data-quantity-id="${product.id}">
                    <button type="button" class="secondary" data-action="quantity" data-id="${product.id}">Actualizeaza</button>
                </div>
            </td>
            <td>${product.lowStockThreshold ?? 5}</td>
            <td>${Number(product.price).toFixed(2)}</td>
            <td>${formatDate(product.createdAt)}</td>
            <td>
                <div class="actions">
                    <button type="button" class="secondary" data-action="edit" data-id="${product.id}">Editeaza</button>
                    <button type="button" class="danger" data-action="delete" data-id="${product.id}">Sterge</button>
                </div>
            </td>
        `;
        productsTableBody.appendChild(row);
    });
}

function renderLowStock(items) {
    lowStockList.innerHTML = "";

    if (items.length === 0) {
        const emptyItem = document.createElement("li");
        emptyItem.textContent = "Nu exista produse cu stoc redus.";
        lowStockList.appendChild(emptyItem);
        return;
    }

    items.forEach((product) => {
        const item = document.createElement("li");
        item.textContent = `${product.name} - ${product.quantity} bucati disponibile`;
        lowStockList.appendChild(item);
    });
}

async function handleSubmit(event) {
    event.preventDefault();

    const lowStockThresholdValue = document.getElementById("lowStockThreshold").value;
    const payload = {
        name: document.getElementById("name").value.trim(),
        description: document.getElementById("description").value.trim() || null,
        category: document.getElementById("category").value.trim(),
        quantity: Number(document.getElementById("quantity").value),
        price: Number(document.getElementById("price").value),
        lowStockThreshold: lowStockThresholdValue === "" ? null : Number(lowStockThresholdValue)
    };

    try {
        const productId = productIdInput.value;

        if (productId) {
            await apiRequest(`/${productId}`, {
                method: "PUT",
                body: JSON.stringify(payload)
            });
            showMessage("Produsul a fost actualizat.");
        } else {
            await apiRequest("", {
                method: "POST",
                body: JSON.stringify(payload)
            });
            showMessage("Produsul a fost adaugat.");
        }

        resetForm();
        await loadProducts();
    } catch (error) {
        showMessage(error.message, true);
    }
}

async function updateQuantity(productId) {
    const quantityInput = document.querySelector(`[data-quantity-id="${productId}"]`);
    const quantity = Number(quantityInput.value);

    try {
        await apiRequest(`/${productId}/quantity`, {
            method: "PATCH",
            body: JSON.stringify({ quantity })
        });
        showMessage("Cantitatea a fost actualizata.");
        await loadProducts();
    } catch (error) {
        showMessage(error.message, true);
    }
}

async function deleteProduct(productId) {
    const confirmed = window.confirm("Stergi acest produs?");

    if (!confirmed) {
        return;
    }

    try {
        await apiRequest(`/${productId}`, {
            method: "DELETE"
        });
        showMessage("Produsul a fost sters.");
        await loadProducts();
    } catch (error) {
        showMessage(error.message, true);
    }
}

function editProduct(productId) {
    const product = products.find((item) => item.id === Number(productId));

    if (!product) {
        return;
    }

    productIdInput.value = product.id;
    document.getElementById("name").value = product.name;
    document.getElementById("description").value = product.description || "";
    document.getElementById("category").value = product.category || "";
    document.getElementById("quantity").value = product.quantity;
    document.getElementById("price").value = product.price;
    document.getElementById("lowStockThreshold").value = product.lowStockThreshold ?? 5;

    formTitle.textContent = "Editeaza produs";
    submitButton.textContent = "Salveaza modificarile";
    cancelEditButton.classList.remove("hidden");
}

function resetForm() {
    productForm.reset();
    productIdInput.value = "";
    formTitle.textContent = "Adauga produs";
    submitButton.textContent = "Adauga produs";
    cancelEditButton.classList.add("hidden");
}

function formatDate(value) {
    if (!value) {
        return "-";
    }

    return new Date(value).toLocaleString("ro-RO");
}

function escapeHtml(value) {
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

productsTableBody.addEventListener("click", (event) => {
    const button = event.target.closest("button");

    if (!button) {
        return;
    }

    const productId = button.dataset.id;

    if (button.dataset.action === "quantity") {
        updateQuantity(productId);
    }

    if (button.dataset.action === "edit") {
        editProduct(productId);
    }

    if (button.dataset.action === "delete") {
        deleteProduct(productId);
    }
});

productForm.addEventListener("submit", handleSubmit);
cancelEditButton.addEventListener("click", resetForm);
refreshButton.addEventListener("click", loadProducts);
apiUrlInput.addEventListener("change", loadProducts);

loadProducts();
