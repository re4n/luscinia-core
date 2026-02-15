--===========================
-- LUSCINIA CORE - INITIAL DB SCHEMA
-- Version: 0.1
-- Description: Core tables for event collection.
--===========================

--===========================
-- SECURITY EVENTS TABLE
-- Store all security events collected from various sources.
--===========================

CREATE TABLE security_events (
    id                   BIGSERIAL PRIMARY KEY,
    event_id             VARCHAR(255) UNIQUE      NOT NULL,

    event_type           VARCHAR(100)             NOT NULL,
    severity             VARCHAR(20)              NOT NULL CHECK (severity IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'HIGH', 'CRITICAL')),
    category             VARCHAR(100),

    source_name          VARCHAR(255)             NOT NULL,
    source_ip            INET,
    source_port          INTEGER,
    source_hostname      VARCHAR(255),

    destination_ip       INET,
    destination_port     INTEGER,
    destination_hostname VARCHAR(255),

    message              TEXT,
    raw_log              TEXT,
    normalized_data      JSONB,

    username             VARCHAR(255),
    user_id              VARCHAR(255),

    event_timestamp      TIMESTAMP WITH TIME ZONE NOT NULL,
    received_timestamp   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIME,
    processed_timestamp  TIMESTAMP WITH TIME ZONE,

    processing_status    VARCHAR(50)              DEFAULT 'PENDING' CHECK (
        processing_status IN ('PENDING', 'PROCESSING', 'PROCESSED', 'FAILED')
        ),

    tags                 VARCHAR(255)[],
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


--===========================
-- PERFORMANCE
--===========================
CREATE INDEX idx_security_events_event_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_source_ip ON security_events(source_ip);
CREATE INDEX idx_security_events_event_timestamp ON security_events(event_timestamp DESC);
CREATE INDEX idx_security_events_received_timestamp ON security_events(received_timestamp DESC);
CREATE INDEX idx_security_events_processing_status ON security_events(processing_status);
CREATE INDEX idx_security_events_normalized_data ON security_events USING GIN(normalized_data);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURN TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_security_events_updated_at
    BEFORE UPDATE ON security_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE security_events IS 'Stores all security events from various sources';
COMMENT ON COLUMN security_events.event_id IS 'Unique identifier for the event (UUID or hash)';
COMMENT ON COLUMN security_events.severity IS 'Severity level: INFO, LOW, MEDIUM, HIGH, CRITICAL';
COMMENT ON COLUMN security_events.normalized_data IS 'JSON field for flexible event data storage';
COMMENT ON COLUMN security_events.processing_status IS 'Current processing status of the event';