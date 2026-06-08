import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
  Share,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import {
  ArrowLeft,
  Star,
  MapPin,
  Heart,
  Share2,
  Calendar,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get("window");
const IS_TABLET = SCREEN_WIDTH >= 768;

// Responsive hero height
const HERO_HEIGHT = IS_TABLET ? SCREEN_HEIGHT * 0.5 : 400;

export default function DestinationDetailScreen() {
  const insets = useSafeAreaInsets();
  const { id } = useLocalSearchParams();
  const [destination, setDestination] = useState(null);
  const [attractions, setAttractions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isSaved, setIsSaved] = useState(false);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    fetchDestinationDetails();
  }, [id]);

  const fetchDestinationDetails = async () => {
    try {
      const response = await fetch(`/api/destinations/${id}`);
      if (response.ok) {
        const data = await response.json();
        setDestination(data.destination);
        setAttractions(data.attractions || []);
      }
    } catch (error) {
      console.error("Error fetching destination:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      const method = isSaved ? "DELETE" : "POST";
      const response = await fetch("/api/saved-destinations", {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ destination_id: id }),
      });

      if (response.ok) {
        setIsSaved(!isSaved);
      }
    } catch (error) {
      console.error("Error saving destination:", error);
    }
  };

  const handleShare = async () => {
    try {
      await Share.share({
        message: `Check out ${destination?.name} on GlobeMate!`,
        url: `https://globemate.app/destination/${id}`,
      });
    } catch (error) {
      console.error("Error sharing:", error);
    }
  };

  if (!fontsLoaded || loading) {
    return null;
  }

  if (!destination) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>Destination not found</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Hero Image */}
        <View style={styles.heroContainer}>
          {destination.image_url && (
            <Image
              source={{ uri: destination.image_url }}
              style={styles.heroImage}
              contentFit="cover"
              transition={100}
            />
          )}

          {/* Header Overlay */}
          <View style={[styles.headerOverlay, { paddingTop: insets.top + 12 }]}>
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => router.back()}
            >
              <ArrowLeft size={24} color="#FFFFFF" />
            </TouchableOpacity>

            <View style={styles.headerActions}>
              <TouchableOpacity
                style={styles.actionButton}
                onPress={handleSave}
              >
                <Heart
                  size={22}
                  color={isSaved ? "#FF6B9D" : "#FFFFFF"}
                  fill={isSaved ? "#FF6B9D" : "transparent"}
                />
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.actionButton}
                onPress={handleShare}
              >
                <Share2 size={22} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
          </View>

          {/* Gradient Overlay */}
          <View style={styles.gradientOverlay} />
        </View>

        {/* Content */}
        <View style={styles.content}>
          {/* Title Section */}
          <View style={styles.titleSection}>
            <Text style={styles.destinationName}>{destination.name}</Text>
            <View style={styles.locationRow}>
              <MapPin size={16} color="#666" />
              <Text style={styles.locationText}>{destination.country}</Text>
            </View>

            {/* Rating & Price */}
            <View style={styles.metaRow}>
              <View style={styles.ratingContainer}>
                <Star size={16} color="#FF6B9D" fill="#FF6B9D" />
                <Text style={styles.ratingText}>
                  {destination.rating || "4.5"}
                </Text>
              </View>
              <Text style={styles.priceRange}>{destination.price_range}</Text>
            </View>
          </View>

          {/* Description */}
          {destination.description && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>About</Text>
              <Text style={styles.description}>{destination.description}</Text>
            </View>
          )}

          {/* Best Time to Visit */}
          {destination.best_time_to_visit && (
            <View style={styles.section}>
              <View style={styles.infoCard}>
                <Calendar size={20} color="#FF6B9D" />
                <View style={styles.infoCardContent}>
                  <Text style={styles.infoCardTitle}>Best Time to Visit</Text>
                  <Text style={styles.infoCardText}>
                    {destination.best_time_to_visit}
                  </Text>
                </View>
              </View>
            </View>
          )}

          {/* Popular Activities */}
          {destination.popular_activities &&
            destination.popular_activities.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>Popular Activities</Text>
                <View style={styles.activitiesContainer}>
                  {destination.popular_activities.map((activity, index) => (
                    <View key={index} style={styles.activityChip}>
                      <Text style={styles.activityText}>{activity}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

          {/* Reviews Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Reviews</Text>
            <TouchableOpacity
              style={styles.writeReviewButton}
              onPress={() =>
                router.push(`/reviews?destinationId=${id}&type=destination`)
              }
            >
              <Text style={styles.writeReviewText}>Write a Review</Text>
            </TouchableOpacity>
          </View>

          {/* Attractions */}
          {attractions.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Top Attractions</Text>
              {attractions.map((attraction) => (
                <TouchableOpacity
                  key={attraction.id}
                  style={styles.attractionCard}
                  activeOpacity={0.9}
                >
                  {attraction.image_url && (
                    <Image
                      source={{ uri: attraction.image_url }}
                      style={styles.attractionImage}
                      contentFit="cover"
                      transition={100}
                    />
                  )}
                  <View style={styles.attractionContent}>
                    <Text style={styles.attractionName} numberOfLines={1}>
                      {attraction.name}
                    </Text>
                    {attraction.category && (
                      <Text style={styles.attractionCategory}>
                        {attraction.category}
                      </Text>
                    )}
                    {attraction.rating && (
                      <View style={styles.attractionRating}>
                        <Star size={12} color="#FF6B9D" fill="#FF6B9D" />
                        <Text style={styles.attractionRatingText}>
                          {attraction.rating}
                        </Text>
                      </View>
                    )}
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          )}
        </View>
      </ScrollView>

      {/* Bottom CTA */}
      <View
        style={[styles.bottomContainer, { paddingBottom: insets.bottom + 16 }]}
      >
        <TouchableOpacity
          style={styles.planTripButton}
          onPress={() => router.push(`/itinerary-create?destination=${id}`)}
          activeOpacity={0.9}
        >
          <Text style={styles.planTripText}>Plan a Trip</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {},
  heroContainer: {
    height: HERO_HEIGHT,
    position: "relative",
  },
  heroImage: {
    width: "100%",
    height: "100%",
  },
  headerOverlay: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: IS_TABLET ? 32 : 20,
    zIndex: 10,
  },
  backButton: {
    width: IS_TABLET ? 52 : 44,
    height: IS_TABLET ? 52 : 44,
    borderRadius: IS_TABLET ? 26 : 22,
    backgroundColor: "rgba(0,0,0,0.3)",
    justifyContent: "center",
    alignItems: "center",
  },
  headerActions: {
    flexDirection: "row",
    gap: IS_TABLET ? 16 : 12,
  },
  actionButton: {
    width: IS_TABLET ? 52 : 44,
    height: IS_TABLET ? 52 : 44,
    borderRadius: IS_TABLET ? 26 : 22,
    backgroundColor: "rgba(0,0,0,0.3)",
    justifyContent: "center",
    alignItems: "center",
  },
  gradientOverlay: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: 100,
    backgroundColor: "transparent",
  },
  content: {
    paddingHorizontal: IS_TABLET ? 48 : 24,
    paddingTop: IS_TABLET ? 32 : 24,
    maxWidth: IS_TABLET ? 900 : "100%",
    alignSelf: "center",
    width: "100%",
  },
  titleSection: {
    marginBottom: IS_TABLET ? 32 : 24,
  },
  destinationName: {
    fontFamily: "Fredoka_500Medium",
    fontSize: IS_TABLET ? 40 : 32,
    color: "#000",
    marginBottom: 8,
  },
  locationRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 12,
  },
  locationText: {
    fontFamily: "Nunito_500Medium",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#666",
  },
  metaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 16,
  },
  ratingContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  ratingText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#000",
  },
  priceRange: {
    fontFamily: "Nunito_700Bold",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#FF6B9D",
  },
  section: {
    marginBottom: IS_TABLET ? 36 : 28,
  },
  sectionTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: IS_TABLET ? 24 : 20,
    color: "#000",
    marginBottom: IS_TABLET ? 20 : 16,
  },
  description: {
    fontFamily: "Nunito_400Regular",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#666",
    lineHeight: IS_TABLET ? 28 : 24,
  },
  infoCard: {
    flexDirection: "row",
    backgroundColor: "#FFF7F8",
    borderRadius: 16,
    padding: IS_TABLET ? 20 : 16,
    borderWidth: 1,
    borderColor: "#FFE5E9",
  },
  infoCardContent: {
    flex: 1,
    marginLeft: 12,
  },
  infoCardTitle: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#000",
    marginBottom: 4,
  },
  infoCardText: {
    fontFamily: "Nunito_400Regular",
    fontSize: IS_TABLET ? 16 : 14,
    color: "#666",
  },
  activitiesContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: IS_TABLET ? 12 : 10,
  },
  activityChip: {
    backgroundColor: "#F5F5F5",
    borderRadius: 20,
    paddingHorizontal: IS_TABLET ? 20 : 16,
    paddingVertical: IS_TABLET ? 12 : 10,
    borderWidth: 1,
    borderColor: "#E0E0E0",
  },
  activityText: {
    fontFamily: "Nunito_500Medium",
    fontSize: IS_TABLET ? 16 : 14,
    color: "#333",
  },
  attractionCard: {
    flexDirection: "row",
    backgroundColor: "#F9FAFB",
    borderRadius: 16,
    marginBottom: IS_TABLET ? 16 : 12,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "#F0F0F0",
  },
  attractionImage: {
    width: IS_TABLET ? 140 : 100,
    height: IS_TABLET ? 140 : 100,
  },
  attractionContent: {
    flex: 1,
    padding: IS_TABLET ? 16 : 12,
    justifyContent: "center",
  },
  attractionName: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: IS_TABLET ? 18 : 16,
    color: "#000",
    marginBottom: 4,
  },
  attractionCategory: {
    fontFamily: "Nunito_400Regular",
    fontSize: IS_TABLET ? 15 : 13,
    color: "#666",
    marginBottom: 6,
  },
  attractionRating: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  attractionRatingText: {
    fontFamily: "Nunito_500Medium",
    fontSize: IS_TABLET ? 15 : 13,
    color: "#666",
  },
  bottomContainer: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: "#FFFFFF",
    paddingHorizontal: IS_TABLET ? 48 : 24,
    paddingTop: IS_TABLET ? 20 : 16,
    borderTopWidth: 1,
    borderTopColor: "#F0F0F0",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 4,
    maxWidth: IS_TABLET ? 900 : "100%",
    alignSelf: "center",
    width: "100%",
  },
  planTripButton: {
    backgroundColor: "#FF6B9D",
    paddingVertical: IS_TABLET ? 20 : 16,
    borderRadius: 28,
    height: IS_TABLET ? 64 : 56,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#FF6B9D",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  planTripText: {
    fontFamily: "Nunito_700Bold",
    fontSize: IS_TABLET ? 18 : 16,
    color: "#FFFFFF",
  },
  errorText: {
    fontFamily: "Nunito_500Medium",
    fontSize: IS_TABLET ? 18 : 16,
    color: "#666",
    textAlign: "center",
    marginTop: 100,
  },
  writeReviewButton: {
    backgroundColor: "#FF6B9D",
    borderRadius: 12,
    paddingVertical: IS_TABLET ? 18 : 14,
    alignItems: "center",
  },
  writeReviewText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#FFFFFF",
  },
});
