import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  TextInput,
  Alert,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import { ArrowLeft, Star, Plus, Camera, X } from "lucide-react-native";
import * as ImagePicker from "expo-image-picker";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";
import { useAuth } from "@/utils/auth/useAuth";
import { useUpload } from "@/utils/useUpload";

export default function ReviewsScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { user } = useAuth();
  const { destinationId, experienceId, type } = useLocalSearchParams();
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddReview, setShowAddReview] = useState(false);
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState("");
  const [images, setImages] = useState([]);
  const { upload } = useUpload();

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    fetchReviews();
  }, [destinationId, experienceId]);

  const fetchReviews = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (destinationId) params.append("destinationId", destinationId);
      if (experienceId) params.append("experienceId", experienceId);

      const response = await fetch(`/api/reviews?${params.toString()}`);
      if (!response.ok) {
        throw new Error("Failed to fetch reviews");
      }
      const data = await response.json();
      setReviews(data.reviews || []);
    } catch (error) {
      console.error("Error fetching reviews:", error);
    } finally {
      setLoading(false);
    }
  };

  const handlePickImages = async () => {
    try {
      const { status } =
        await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (status !== "granted") {
        Alert.alert(
          "Permission Required",
          "Please allow access to your photos to upload images.",
        );
        return;
      }

      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsMultipleSelection: true,
        quality: 0.8,
        selectionLimit: 3 - images.length,
      });

      if (!result.canceled && result.assets) {
        const uploadedUrls = [];
        for (const asset of result.assets) {
          const uploadedUrl = await upload(asset.uri);
          uploadedUrls.push(uploadedUrl);
        }
        setImages([...images, ...uploadedUrls]);
      }
    } catch (error) {
      console.error("Error picking images:", error);
      Alert.alert("Error", "Failed to upload images. Please try again.");
    }
  };

  const handleRemoveImage = (index) => {
    setImages(images.filter((_, i) => i !== index));
  };

  const handleSubmitReview = async () => {
    if (!user) {
      Alert.alert("Sign In Required", "Please sign in to leave a review.");
      return;
    }

    if (rating === 0) {
      Alert.alert("Rating Required", "Please select a star rating.");
      return;
    }

    if (!comment.trim()) {
      Alert.alert("Comment Required", "Please write a comment.");
      return;
    }

    try {
      const response = await fetch("/api/reviews", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user.id,
          destinationId: destinationId ? parseInt(destinationId) : null,
          experienceId: experienceId ? parseInt(experienceId) : null,
          rating,
          comment: comment.trim(),
          images: images.length > 0 ? images : null,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit review");
      }

      setShowAddReview(false);
      setRating(0);
      setComment("");
      setImages([]);
      fetchReviews();
      Alert.alert("Success", "Your review has been posted!");
    } catch (error) {
      console.error("Error submitting review:", error);
      Alert.alert("Error", "Could not submit your review. Please try again.");
    }
  };

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    router.back();
  };

  const renderStars = (count, onPress = null) => {
    return (
      <View style={styles.starsRow}>
        {[1, 2, 3, 4, 5].map((star) => (
          <TouchableOpacity
            key={star}
            onPress={() => onPress && onPress(star)}
            disabled={!onPress}
          >
            <Star
              size={onPress ? 32 : 16}
              color="#FF6B9D"
              fill={star <= count ? "#FF6B9D" : "transparent"}
            />
          </TouchableOpacity>
        ))}
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Reviews</Text>

        <TouchableOpacity
          style={styles.addButton}
          onPress={() => setShowAddReview(!showAddReview)}
        >
          <Plus size={24} color="#FFF" />
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Add Review Form */}
        {showAddReview && (
          <View style={styles.addReviewCard}>
            <Text style={styles.addReviewTitle}>Write a Review</Text>

            <Text style={styles.label}>Your Rating</Text>
            {renderStars(rating, setRating)}

            <Text style={styles.label}>Your Comment</Text>
            <TextInput
              style={styles.commentInput}
              value={comment}
              onChangeText={setComment}
              placeholder="Share your experience..."
              placeholderTextColor="#999"
              multiline
              numberOfLines={4}
              textAlignVertical="top"
            />

            {/* Photo Upload */}
            <Text style={styles.label}>Photos (Optional)</Text>
            <View style={styles.photosContainer}>
              {images.map((imageUrl, index) => (
                <View key={index} style={styles.photoWrapper}>
                  <Image
                    source={{ uri: imageUrl }}
                    style={styles.photoThumbnail}
                    contentFit="cover"
                  />
                  <TouchableOpacity
                    style={styles.removePhotoButton}
                    onPress={() => handleRemoveImage(index)}
                  >
                    <X size={16} color="#FFF" />
                  </TouchableOpacity>
                </View>
              ))}

              {images.length < 3 && (
                <TouchableOpacity
                  style={styles.addPhotoButton}
                  onPress={handlePickImages}
                >
                  <Camera size={24} color="#FF6B9D" />
                  <Text style={styles.addPhotoText}>Add Photo</Text>
                </TouchableOpacity>
              )}
            </View>

            <View style={styles.addReviewActions}>
              <TouchableOpacity
                style={styles.cancelButton}
                onPress={() => {
                  setShowAddReview(false);
                  setRating(0);
                  setComment("");
                  setImages([]);
                }}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.submitButton}
                onPress={handleSubmitReview}
              >
                <Text style={styles.submitButtonText}>Submit Review</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* Reviews List */}
        {reviews.length === 0 && !loading && (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>
              No reviews yet. Be the first to share your experience!
            </Text>
          </View>
        )}

        {reviews.map((review) => (
          <View key={review.id} style={styles.reviewCard}>
            <View style={styles.reviewHeader}>
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>
                  {(review.user_name || "A").charAt(0).toUpperCase()}
                </Text>
              </View>

              <View style={styles.reviewHeaderInfo}>
                <Text style={styles.userName}>
                  {review.user_name || "Anonymous"}
                </Text>
                <Text style={styles.reviewDate}>
                  {new Date(review.created_at).toLocaleDateString()}
                </Text>
              </View>

              {renderStars(review.rating)}
            </View>

            <Text style={styles.reviewComment}>{review.comment}</Text>

            {/* Review Photos */}
            {review.images && review.images.length > 0 && (
              <View style={styles.reviewPhotos}>
                {review.images.map((imageUrl, index) => (
                  <Image
                    key={index}
                    source={{ uri: imageUrl }}
                    style={styles.reviewPhoto}
                    contentFit="cover"
                  />
                ))}
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#F0F0F0",
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#F5F5F5",
    justifyContent: "center",
    alignItems: "center",
  },
  headerTitle: {
    fontFamily: "Fredoka_500Medium",
    fontSize: 20,
    color: "#000",
    flex: 1,
    marginLeft: 12,
  },
  addButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#FF6B9D",
    justifyContent: "center",
    alignItems: "center",
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: 24,
    paddingTop: 20,
  },
  addReviewCard: {
    backgroundColor: "#FFF9FA",
    borderRadius: 16,
    padding: 20,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: "#FFE5ED",
  },
  addReviewTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: 20,
    color: "#000",
    marginBottom: 16,
  },
  label: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 14,
    color: "#000",
    marginBottom: 12,
    marginTop: 8,
  },
  starsRow: {
    flexDirection: "row",
    gap: 8,
    marginBottom: 16,
  },
  commentInput: {
    backgroundColor: "#FFFFFF",
    borderRadius: 12,
    padding: 16,
    fontFamily: "Nunito_400Regular",
    fontSize: 15,
    color: "#000",
    borderWidth: 1,
    borderColor: "#E5E7EB",
    minHeight: 120,
    marginBottom: 16,
  },
  photosContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    marginBottom: 16,
  },
  photoWrapper: {
    position: "relative",
  },
  photoThumbnail: {
    width: 80,
    height: 80,
    borderRadius: 12,
    backgroundColor: "#F5F5F5",
  },
  removePhotoButton: {
    position: "absolute",
    top: 4,
    right: 4,
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: "rgba(0,0,0,0.6)",
    justifyContent: "center",
    alignItems: "center",
  },
  addPhotoButton: {
    width: 80,
    height: 80,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: "#FF6B9D",
    borderStyle: "dashed",
    justifyContent: "center",
    alignItems: "center",
  },
  addPhotoText: {
    fontFamily: "Nunito_500Medium",
    fontSize: 11,
    color: "#FF6B9D",
    marginTop: 4,
  },
  addReviewActions: {
    flexDirection: "row",
    gap: 12,
  },
  cancelButton: {
    flex: 1,
    backgroundColor: "#FFFFFF",
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
  cancelButtonText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 15,
    color: "#666",
  },
  submitButton: {
    flex: 1,
    backgroundColor: "#FF6B9D",
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
  },
  submitButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 15,
    color: "#FFFFFF",
  },
  reviewCard: {
    backgroundColor: "#F9FAFB",
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
  reviewHeader: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 12,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#FF6B9D",
    justifyContent: "center",
    alignItems: "center",
    marginRight: 12,
  },
  avatarText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#FFFFFF",
  },
  reviewHeaderInfo: {
    flex: 1,
  },
  userName: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 15,
    color: "#000",
    marginBottom: 2,
  },
  reviewDate: {
    fontFamily: "Nunito_400Regular",
    fontSize: 12,
    color: "#999",
  },
  reviewComment: {
    fontFamily: "Nunito_400Regular",
    fontSize: 14,
    color: "#666",
    lineHeight: 20,
  },
  reviewPhotos: {
    flexDirection: "row",
    gap: 8,
    marginTop: 12,
    flexWrap: "wrap",
  },
  reviewPhoto: {
    width: 100,
    height: 100,
    borderRadius: 12,
    backgroundColor: "#F5F5F5",
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 60,
  },
  emptyText: {
    fontFamily: "Nunito_400Regular",
    fontSize: 16,
    color: "#999",
    textAlign: "center",
  },
});
