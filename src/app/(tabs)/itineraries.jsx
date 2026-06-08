import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Dimensions,
  Share,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  Plus,
  Calendar,
  MapPin,
  Clock,
  Sparkles,
  Trash2,
  Share2,
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
import { useAuth } from "@/utils/auth/useAuth";
import analytics from "@/utils/analytics";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const IS_TABLET = SCREEN_WIDTH >= 768;

export default function ItinerariesScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { user } = useAuth();
  const [itineraries, setItineraries] = useState([]);
  const [loading, setLoading] = useState(true);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    analytics.trackScreenView("itineraries");
    fetchItineraries();
  }, []);

  const fetchItineraries = async () => {
    try {
      const response = await fetch(`/api/itineraries?userId=${user?.id || 0}`);
      if (response.ok) {
        const data = await response.json();
        setItineraries(data.itineraries || []);

        analytics.trackEvent(
          "itineraries_loaded",
          { count: data.itineraries?.length || 0 },
          "content",
        );
      }
    } catch (error) {
      console.error("Error fetching itineraries:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      const response = await fetch(`/api/itineraries/${id}`, {
        method: "DELETE",
      });

      if (response.ok) {
        setItineraries(itineraries.filter((item) => item.id !== id));
        analytics.trackEvent("itinerary_deleted", { id }, "engagement");
      }
    } catch (error) {
      console.error("Error deleting itinerary:", error);
    }
  };

  const handleShare = async (itinerary) => {
    try {
      const shareText = `Check out my ${itinerary.title} itinerary!\n\n${
        itinerary.description || ""
      }\n\nDuration: ${itinerary.duration_days} days${
        itinerary.destination_name
          ? `\nDestination: ${itinerary.destination_name}`
          : ""
      }${itinerary.is_ai_generated ? "\n\n✨ Created with AI" : ""}`;

      await Share.share({
        message: shareText,
        title: itinerary.title,
      });

      analytics.trackEvent(
        "itinerary_shared",
        {
          id: itinerary.id,
          title: itinerary.title,
        },
        "engagement",
      );
    } catch (error) {
      console.error("Error sharing itinerary:", error);
    }
  };

  const handleCreatePress = () => {
    analytics.trackFeatureUse("create_itinerary_button", {
      screen: "itineraries",
    });
    router.push("/itinerary-create");
  };

  if (!fontsLoaded || loading) {
    return (
      <View style={[styles.container, styles.loadingContainer]}>
        <ActivityIndicator size="large" color="#FF6B9D" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <Text style={styles.headerTitle}>My Itineraries</Text>
        <TouchableOpacity
          style={styles.createButton}
          onPress={handleCreatePress}
          activeOpacity={0.9}
        >
          <Plus size={IS_TABLET ? 28 : 24} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {itineraries.length === 0 ? (
          <View style={styles.emptyState}>
            <View style={styles.emptyIcon}>
              <Calendar size={IS_TABLET ? 56 : 48} color="#FF6B9D" />
            </View>
            <Text style={styles.emptyTitle}>No Itineraries Yet</Text>
            <Text style={styles.emptyDescription}>
              Start planning your dream trip! Create an itinerary with AI
              assistance or build one manually.
            </Text>
            <TouchableOpacity
              style={styles.emptyButton}
              onPress={handleCreatePress}
              activeOpacity={0.9}
            >
              <Plus size={20} color="#FFFFFF" />
              <Text style={styles.emptyButtonText}>Create Itinerary</Text>
            </TouchableOpacity>
          </View>
        ) : (
          itineraries.map((itinerary) => (
            <TouchableOpacity
              key={itinerary.id}
              style={styles.itineraryCard}
              activeOpacity={0.9}
              onPress={() => router.push(`/itinerary/${itinerary.id}`)}
            >
              <View style={styles.itineraryHeader}>
                <View style={styles.itineraryTitleContainer}>
                  <Text style={styles.itineraryTitle} numberOfLines={2}>
                    {itinerary.title}
                  </Text>
                  {itinerary.is_ai_generated && (
                    <View style={styles.aiBadge}>
                      <Sparkles size={12} color="#FF9500" />
                      <Text style={styles.aiBadgeText}>AI Generated</Text>
                    </View>
                  )}
                </View>
                <View style={styles.actionButtons}>
                  <TouchableOpacity
                    style={styles.shareButton}
                    onPress={(e) => {
                      e.stopPropagation();
                      handleShare(itinerary);
                    }}
                  >
                    <Share2 size={18} color="#FFFFFF" />
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.deleteButton}
                    onPress={(e) => {
                      e.stopPropagation();
                      handleDelete(itinerary.id);
                    }}
                  >
                    <Trash2 size={18} color="#FF3B30" />
                  </TouchableOpacity>
                </View>
              </View>

              <View style={styles.itineraryMeta}>
                {itinerary.duration_days && (
                  <View style={styles.metaItem}>
                    <Clock size={16} color={theme.iconSecondary} />
                    <Text style={styles.metaText}>
                      {itinerary.duration_days} days
                    </Text>
                  </View>
                )}
                {itinerary.destination_name && (
                  <View style={styles.metaItem}>
                    <MapPin size={16} color={theme.iconSecondary} />
                    <Text style={styles.metaText} numberOfLines={1}>
                      {itinerary.destination_name}
                    </Text>
                  </View>
                )}
              </View>

              {itinerary.description && (
                <Text style={styles.itineraryDescription} numberOfLines={3}>
                  {itinerary.description}
                </Text>
              )}
            </TouchableOpacity>
          ))
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  loadingContainer: {
    justifyContent: "center",
    alignItems: "center",
  },
  header: {
    paddingHorizontal: IS_TABLET ? 48 : 24,
    paddingBottom: IS_TABLET ? 24 : 20,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  headerTitle: {
    fontFamily: " Fredoka_500Medium",
    fontSize: IS_TABLET ? 32 : 28,
    color: "#1A1A1A",
  },
  createButton: {
    width: IS_TABLET ? 56 : 48,
    height: IS_TABLET ? 56 : 48,
    borderRadius: IS_TABLET ? 28 : 24,
    backgroundColor: "#FF6B9D",
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#FF6B9D",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: IS_TABLET ? 48 : 24,
    maxWidth: IS_TABLET ? 900 : "100%",
    alignSelf: "center",
    width: "100%",
  },
  emptyState: {
    alignItems: "center",
    paddingTop: 100,
  },
  emptyIcon: {
    width: IS_TABLET ? 120 : 100,
    height: IS_TABLET ? 120 : 100,
    borderRadius: IS_TABLET ? 60 : 50,
    backgroundColor: "#FFF7F8",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 24,
  },
  emptyTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: IS_TABLET ? 24 : 20,
    color: "#1A1A1A",
    marginBottom: 12,
    textAlign: "center",
  },
  emptyDescription: {
    fontFamily: "Nunito_400Regular",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#666",
    textAlign: "center",
    lineHeight: IS_TABLET ? 26 : 22,
    marginBottom: 32,
    paddingHorizontal: 24,
  },
  emptyButton: {
    backgroundColor: "#FF6B9D",
    borderRadius: 24,
    paddingVertical: IS_TABLET ? 18 : 14,
    paddingHorizontal: IS_TABLET ? 32 : 24,
    flexDirection: "row",
    alignItems: "center",
  },
  emptyButtonText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: IS_TABLET ? 17 : 15,
    color: "#FFFFFF",
    marginLeft: 8,
  },
  itineraryCard: {
    backgroundColor: "#F9FAFB",
    borderRadius: 20,
    padding: IS_TABLET ? 24 : 20,
    marginBottom: IS_TABLET ? 20 : 16,
    borderWidth: 1,
    borderColor: "#F0F0F0",
  },
  itineraryHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 12,
  },
  itineraryTitleContainer: {
    flex: 1,
    marginRight: 12,
  },
  itineraryTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: IS_TABLET ? 20 : 18,
    color: "#1A1A1A",
    marginBottom: 4,
  },
  aiBadge: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#FFF7E6",
    borderRadius: 12,
    paddingVertical: 4,
    paddingHorizontal: 10,
    alignSelf: "flex-start",
  },
  aiBadgeText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: IS_TABLET ? 13 : 11,
    color: "#FF9500",
    marginLeft: 4,
  },
  actionButtons: {
    flexDirection: "row",
    gap: 8,
  },
  shareButton: {
    width: IS_TABLET ? 40 : 36,
    height: IS_TABLET ? 40 : 36,
    borderRadius: IS_TABLET ? 20 : 18,
    backgroundColor: "#007AFF",
    justifyContent: "center",
    alignItems: "center",
  },
  deleteButton: {
    width: IS_TABLET ? 40 : 36,
    height: IS_TABLET ? 40 : 36,
    borderRadius: IS_TABLET ? 20 : 18,
    backgroundColor: "#FFFFFF",
    justifyContent: "center",
    alignItems: "center",
  },
  itineraryMeta: {
    flexDirection: "row",
    alignItems: "center",
    gap: 16,
    marginTop: 12,
  },
  metaItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  metaText: {
    fontFamily: "Nunito_500Medium",
    fontSize: IS_TABLET ? 15 : 13,
    color: "#666",
  },
  itineraryDescription: {
    fontFamily: "Nunito_400Regular",
    fontSize: IS_TABLET ? 16 : 14,
    color: "#666",
    lineHeight: IS_TABLET ? 24 : 20,
    marginTop: 12,
  },
});
