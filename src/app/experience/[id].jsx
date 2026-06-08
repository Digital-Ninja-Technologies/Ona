import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Share,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import {
  ArrowLeft,
  Star,
  Clock,
  Users,
  MapPin,
  Share2,
  Heart,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";

export default function ExperienceDetailScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { id } = useLocalSearchParams();
  const [experience, setExperience] = useState(null);
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
    if (id) {
      fetchExperience();
    }
  }, [id]);

  const fetchExperience = async () => {
    try {
      setLoading(true);
      const response = await fetch(`/api/experiences/${id}`);
      if (!response.ok) {
        throw new Error("Failed to fetch experience");
      }
      const data = await response.json();
      setExperience(data);
    } catch (error) {
      console.error("Error fetching experience:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleShare = async () => {
    try {
      await Share.share({
        message: `Check out this experience: ${experience?.title}`,
        url: `https://globemate.app/experience/${id}`,
      });
    } catch (error) {
      console.error("Error sharing:", error);
    }
  };

  const handleBookNow = () => {
    router.push(`/booking-flow?experienceId=${id}&price=${experience?.price}`);
  };

  const handleBackPress = () => {
    router.back();
  };

  if (!fontsLoaded || loading) {
    return null;
  }

  if (!experience) {
    return null;
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      {/* Header Image */}
      {experience.image_url && (
        <Image
          source={{ uri: experience.image_url }}
          style={styles.headerImage}
          contentFit="cover"
          transition={100}
        />
      )}

      {/* Header Buttons */}
      <View style={[styles.headerButtons, { top: insets.top + 16 }]}>
        <TouchableOpacity style={styles.headerButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color="#FFF" />
        </TouchableOpacity>

        <View style={styles.headerButtonsRight}>
          <TouchableOpacity style={styles.headerButton} onPress={handleShare}>
            <Share2 size={22} color="#FFF" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => setIsSaved(!isSaved)}
          >
            <Heart
              size={22}
              color="#FFF"
              fill={isSaved ? "#FF6B9D" : "transparent"}
            />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Title & Rating */}
        <View style={styles.titleSection}>
          <Text style={styles.title}>{experience.title}</Text>
          <View style={styles.ratingRow}>
            <Star size={18} color="#FF6B9D" fill="#FF6B9D" />
            <Text style={styles.ratingText}>
              {experience.rating || "5.0"} ({experience.total_bookings || 0}{" "}
              bookings)
            </Text>
          </View>
        </View>

        {/* Quick Info */}
        <View style={styles.quickInfo}>
          {experience.duration_hours && (
            <View style={styles.infoChip}>
              <Clock size={16} color="#666" />
              <Text style={styles.infoText}>{experience.duration_hours}h</Text>
            </View>
          )}

          {experience.max_participants && (
            <View style={styles.infoChip}>
              <Users size={16} color="#666" />
              <Text style={styles.infoText}>
                Up to {experience.max_participants}
              </Text>
            </View>
          )}

          {experience.category && (
            <View style={styles.infoChip}>
              <MapPin size={16} color="#666" />
              <Text style={styles.infoText}>{experience.category}</Text>
            </View>
          )}
        </View>

        {/* Description */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>About This Experience</Text>
          <Text style={styles.description}>
            {experience.description ||
              "An unforgettable local experience that will give you unique insights into the culture and traditions of the area."}
          </Text>
        </View>

        {/* What's Included */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>What's Included</Text>
          <View style={styles.bulletPoint}>
            <Text style={styles.bullet}>•</Text>
            <Text style={styles.bulletText}>Professional local guide</Text>
          </View>
          <View style={styles.bulletPoint}>
            <Text style={styles.bullet}>•</Text>
            <Text style={styles.bulletText}>All entrance fees</Text>
          </View>
          <View style={styles.bulletPoint}>
            <Text style={styles.bullet}>•</Text>
            <Text style={styles.bulletText}>
              Hotel pickup and drop-off (if selected)
            </Text>
          </View>
          <View style={styles.bulletPoint}>
            <Text style={styles.bullet}>•</Text>
            <Text style={styles.bulletText}>Complimentary refreshments</Text>
          </View>
        </View>

        {/* Reviews Preview */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Reviews</Text>
            <TouchableOpacity
              onPress={() =>
                router.push(`/reviews?experienceId=${id}&type=experience`)
              }
            >
              <Text style={styles.seeAllText}>See all</Text>
            </TouchableOpacity>
          </View>
          <Text style={styles.reviewComingSoon}>
            Reviews coming soon. Be the first to book!
          </Text>
        </View>
      </ScrollView>

      {/* Book Now Footer */}
      <View style={[styles.bookFooter, { paddingBottom: insets.bottom + 16 }]}>
        <View style={styles.priceContainer}>
          <Text style={styles.priceLabel}>From</Text>
          <Text style={styles.price}>${experience.price}</Text>
          <Text style={styles.priceSubtext}>per person</Text>
        </View>

        <TouchableOpacity
          style={styles.bookButton}
          onPress={handleBookNow}
          activeOpacity={0.9}
        >
          <Text style={styles.bookButtonText}>Book Now</Text>
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
  headerImage: {
    width: "100%",
    height: 320,
    backgroundColor: "#F5F5F5",
  },
  headerButtons: {
    position: "absolute",
    left: 0,
    right: 0,
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    zIndex: 10,
  },
  headerButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: "rgba(0,0,0,0.4)",
    justifyContent: "center",
    alignItems: "center",
  },
  headerButtonsRight: {
    flexDirection: "row",
    gap: 12,
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: 24,
    paddingTop: 20,
  },
  titleSection: {
    marginBottom: 16,
  },
  title: {
    fontFamily: "Fredoka_500Medium",
    fontSize: 28,
    color: "#000",
    marginBottom: 8,
  },
  ratingRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  ratingText: {
    fontFamily: "Nunito_500Medium",
    fontSize: 15,
    color: "#666",
  },
  quickInfo: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    marginBottom: 24,
  },
  infoChip: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#F9FAFB",
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 8,
    gap: 6,
  },
  infoText: {
    fontFamily: "Nunito_500Medium",
    fontSize: 13,
    color: "#666",
  },
  section: {
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },
  sectionTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: 20,
    color: "#000",
    marginBottom: 12,
  },
  description: {
    fontFamily: "Nunito_400Regular",
    fontSize: 15,
    color: "#666",
    lineHeight: 24,
  },
  bulletPoint: {
    flexDirection: "row",
    marginBottom: 8,
  },
  bullet: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 16,
    color: "#FF6B9D",
    marginRight: 12,
  },
  bulletText: {
    fontFamily: "Nunito_400Regular",
    fontSize: 15,
    color: "#666",
    flex: 1,
  },
  seeAllText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 14,
    color: "#FF6B9D",
  },
  reviewComingSoon: {
    fontFamily: "Nunito_400Regular",
    fontSize: 14,
    color: "#999",
    fontStyle: "italic",
  },
  bookFooter: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 24,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: "#F0F0F0",
    backgroundColor: "#FFFFFF",
  },
  priceContainer: {
    flexDirection: "row",
    alignItems: "baseline",
    gap: 6,
  },
  priceLabel: {
    fontFamily: "Nunito_400Regular",
    fontSize: 13,
    color: "#666",
  },
  price: {
    fontFamily: "Nunito_700Bold",
    fontSize: 28,
    color: "#FF6B9D",
  },
  priceSubtext: {
    fontFamily: "Nunito_400Regular",
    fontSize: 12,
    color: "#999",
  },
  bookButton: {
    backgroundColor: "#FF6B9D",
    borderRadius: 24,
    paddingHorizontal: 32,
    paddingVertical: 14,
  },
  bookButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#FFFFFF",
  },
});
