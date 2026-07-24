abstract interface class DocumentBackend {
  Future<BackendSession> open(OpenDocumentRequest request);
  Future<DocumentDelta> apply(CommandDto command);
  Future<DocumentDelta> undo();
  Future<DocumentDelta> redo();
  Future<ViewportSnapshot> queryViewport(ViewportQuery query);
  Future<HitTestResult> hitTest(HitTestQuery query);
  Stream<BackendEvent> get events;
  Future<void> checkpoint();
  Future<void> close();
}

// DTO definitions should live in a package that imports neither Flutter widgets
// nor DocumentBloc/Renderer types.
