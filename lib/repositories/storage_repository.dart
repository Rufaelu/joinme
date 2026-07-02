class StorageRepository {
  Future<String> uploadProfilePicture(String userId, String filePath) async {
    // Return a free, dynamic public avatar generator to avoid Firebase Storage billing
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$userId';
  }

  Future<String> uploadEventImage(String eventId, String filePath) async {
    // Return a free public event cover image from Unsplash to avoid Firebase Storage billing
    return 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=600';
  }

  Future<void> deleteFile(String fileUrl) async {
    // No-op since we use public placeholder URLs
  }
}
