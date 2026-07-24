PRAGMA foreign_keys = ON;

CREATE TABLE meta (
    key TEXT PRIMARY KEY,
    value BLOB NOT NULL
) STRICT;

CREATE TABLE spaces (
    space_id BLOB PRIMARY KEY CHECK(length(space_id) = 16),
    kind INTEGER NOT NULL,
    ordinal INTEGER,
    payload BLOB NOT NULL
) STRICT;

CREATE TABLE elements (
    element_rowid INTEGER PRIMARY KEY,
    element_id BLOB NOT NULL UNIQUE CHECK(length(element_id) = 16),
    space_id BLOB NOT NULL CHECK(length(space_id) = 16),
    element_type INTEGER NOT NULL,
    z_order INTEGER NOT NULL,
    min_x REAL NOT NULL,
    min_y REAL NOT NULL,
    max_x REAL NOT NULL,
    max_y REAL NOT NULL,
    revision INTEGER NOT NULL,
    payload_version INTEGER NOT NULL,
    payload BLOB NOT NULL,
    FOREIGN KEY(space_id) REFERENCES spaces(space_id) ON DELETE CASCADE,
    CHECK(min_x <= max_x),
    CHECK(min_y <= max_y)
) STRICT;

CREATE INDEX idx_elements_space_z ON elements(space_id, z_order);
CREATE INDEX idx_elements_id ON elements(element_id);

CREATE TABLE history (
    sequence INTEGER PRIMARY KEY,
    command_id BLOB NOT NULL UNIQUE CHECK(length(command_id) = 16),
    document_revision INTEGER NOT NULL,
    command_type INTEGER NOT NULL,
    forward_payload BLOB NOT NULL,
    inverse_payload BLOB NOT NULL,
    committed_at_micros INTEGER NOT NULL
) STRICT;

CREATE TABLE session_state (
    singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
    document_revision INTEGER NOT NULL,
    history_cursor INTEGER NOT NULL,
    active_space_id BLOB,
    camera_payload BLOB NOT NULL,
    tool_payload BLOB NOT NULL
) STRICT;
