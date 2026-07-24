pub trait DocumentStore {
    fn load_manifest(&self) -> Result<DocumentManifest, StoreError>;
    fn load_elements(&self, space: SpaceId) -> Result<Vec<StoredElement>, StoreError>;
    fn commit(&mut self, commit: StorageCommit) -> Result<CommitReceipt, StoreError>;
    fn integrity_check(&mut self, level: IntegrityLevel) -> Result<IntegrityReport, StoreError>;
    fn create_backup(&mut self, destination: &std::path::Path) -> Result<(), StoreError>;
}

pub struct StorageCommit {
    pub expected_revision: u64,
    pub element_mutations: Vec<ElementMutation>,
    pub history_mutation: HistoryMutation,
    pub session_update: SessionUpdate,
}
