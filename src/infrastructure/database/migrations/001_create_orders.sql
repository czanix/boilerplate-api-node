-- =============================================================================
-- Migration 001: Create Orders
-- Czanix Boilerplate — https://czanix.com
-- ADR-001: INT PK + UUID público
-- ADR-004: Database design principles
-- =============================================================================

CREATE TABLE IF NOT EXISTS orders (
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,    -- INT basta: orders < 2B
    public_id   UUID NOT NULL DEFAULT gen_random_uuid(),
    customer_id TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'pending',
    deleted_at  TIMESTAMPTZ NULL,                                -- soft delete
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_orders_public_id UNIQUE (public_id),
    CONSTRAINT chk_orders_status CHECK (status IN ('pending', 'confirmed', 'cancelled', 'delivered'))
);

CREATE TABLE IF NOT EXISTS order_items (
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    INT NOT NULL REFERENCES orders(id),              -- FK inegociável
    product_id  TEXT NOT NULL,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),            -- constraint no banco
    unit_price  NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0), -- NUNCA float para dinheiro
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice filtrado: só indexa registros ativos
-- Serve a query: SELECT * FROM orders WHERE customer_id = ? AND deleted_at IS NULL
CREATE INDEX IF NOT EXISTS ix_orders_customer_active
    ON orders (customer_id, created_at DESC)
    WHERE deleted_at IS NULL;

-- Índice para FK: PostgreSQL não cria automaticamente
CREATE INDEX IF NOT EXISTS ix_order_items_order
    ON order_items (order_id);
