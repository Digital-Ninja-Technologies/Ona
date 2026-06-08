import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  RefreshControl,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import { ArrowLeft, Heart, MapPin, Star, Trash2 } from "lucide-react-native";
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

export default function WishlistScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { user } = useAuth();
  const [savedDestinations, setSavedDestinations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    if (user) {
      fetchSavedDestinations();
    }
  }, [user]);

  const fetchSavedDestinations = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const response = await fetch(`/api/saved-destinations?userId=${user.id}`);
      if (!response.ok) {
        throw new Error("Failed to fetch saved destinations");
      }
      const data = await response.json();
      setSavedDestinations(data.destinations || []);
    } catch (error) {
      console.error("Error fetching saved destinations:", error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRemove = async (destinationId) => {
    try {
      const response = await fetch("/api/saved-destinations", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user.id,
          destinationId: destinationId,
        }),
      });

      if (response.ok) {
        setSavedDestinations(
          savedDestinations.filter((dest) => dest.id !== destinationId),
        );
      }
    } catch (error) {
      console.error("Error removing destination:", error);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    fetchSavedDestinations();
  };

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    router.back();
  };

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>My Wishlist</Text>
        <View style={styles.headerRight}>
          <Heart size={24} color="#FF6B9D" fill="#FF6B9D" />
        </View>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {!user && (
          <View style={styles.emptyState}>
            <Heart size={64} color="#E5E7EB" />
            <Text style={styles.emptyTitle}>Sign In Required</Text>
            <Text style={styles.emptyText}>
              Please sign in to save destinations to your wishlist.
            </Text>
          </View>
        )}

        {user && savedDestinations.length === 0 && !loading && (
          <View style={styles.emptyState}>
            <Heart size={64} color="#E5E7EB" />
            <Text style={styles.emptyTitle}>Your wishlist is empty</Text>
            <Text style={styles.emptyText}>
              Start saving destinations you'd love to visit!
            </Text>
            <TouchableOpacity
              style={styles.exploreButton}
              onPress={() => router.push("/(tabs)/home")}
            >
              <Text style={styles.exploreButtonText}>Explore Destinations</Text>
            </TouchableOpacity>
          </View>
        )}

        {savedDestinations.map((destination) => (
          <TouchableOpacity
            key={destination.id}
            style={styles.destinationCard}
            onPress={() => router.push(`/destination/${destination.id}`)}
            activeOpacity={0.9}
          >
            {destination.image_url && (
              <Image
                source={{ uri: destination.image_url }}
                style={styles.destinationImage}
                contentFit="cover"
                transition={100}
              />
            )}

            <TouchableOpacity
              style={styles.removeButton}
              onPress={() => handleRemove(destination.id)}
            >
              <Trash2 size={18} color="#FFF" />
            </TouchableOpacity>

            <View style={styles.destinationContent}>
              <View style={styles.destinationInfo}>
                <Text style={styles.destinationName} numberOfLines={1}>
                  {destination.name}
                </Text>

                <View style={styles.locationRow}>
                  <MapPin size={14} color="#999" />
                  <Text style={styles.locationText}>{destination.country}</Text>
                </View>

                <View style={styles.metaRow}>
                  <View style={styles.ratingContainer}>
                    <Star size={14} color="#FF6B9D" fill="#FF6B9D" />
                    <Text style={styles.ratingText}>
                      {destination.rating || "4.5"}
                    </Text>
                  </View>

                  {destination.price_range && (
                    <Text style={styles.priceRange}>
                      {destination.price_range}
                    </Text>
                  )}
                </View>
              </View>
            </View>
          </TouchableOpacity>
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
  headerRight: {
    width: 40,
    height: 40,
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
  destinationCard: {
    backgroundColor: "#FFFFFF",
    borderRadius: 20,
    marginBottom: 20,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "#F0F0F0",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  destinationImage: {
    width: "100%",
    height: 200,
    backgroundColor: "#F5F5F5",
  },
  removeButton: {
    position: "absolute",
    top: 12,
    right: 12,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: "rgba(0,0,0,0.6)",
    justifyContent: "center",
    alignItems: "center",
    zIndex: 10,
  },
  destinationContent: {
    padding: 16,
  },
  destinationInfo: {
    flex: 1,
  },
  destinationName: {
    fontFamily: "Nunito_700Bold",
    fontSize: 20,
    color: "#000",
    marginBottom: 6,
  },
  locationRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    marginBottom: 8,
  },
  locationText: {
    fontFamily: "Nunito_500Medium",
    fontSize: 14,
    color: "#999",
  },
  metaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  ratingContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  ratingText: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 14,
    color: "#000",
  },
  priceRange: {
    fontFamily: "Nunito_700Bold",
    fontSize: 14,
    color: "#FF6B9D",
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 80,
    paddingHorizontal: 32,
  },
  emptyTitle: {
    fontFamily: "Fredoka_500Medium",
    fontSize: 24,
    color: "#000",
    marginTop: 24,
    marginBottom: 12,
  },
  emptyText: {
    fontFamily: "Nunito_400Regular",
    fontSize: 16,
    color: "#999",
    textAlign: "center",
    lineHeight: 24,
    marginBottom: 24,
  },
  exploreButton: {
    backgroundColor: "#FF6B9D",
    borderRadius: 24,
    paddingHorizontal: 32,
    paddingVertical: 14,
  },
  exploreButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#FFFFFF",
  },
});
