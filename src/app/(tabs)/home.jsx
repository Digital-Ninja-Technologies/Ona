import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image as RNImage,
  TextInput,
  Dimensions,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  Sparkles,
  DollarSign,
  Package,
  MapPin,
  Star,
  ChevronRight,
  Search,
} from "lucide-react-native";
import {
  useFonts,
  Poppins_400Regular,
  Poppins_500Medium,
  Poppins_600SemiBold,
} from "@expo-google-fonts/poppins";
import { InstrumentSans_500Medium } from "@expo-google-fonts/instrument-sans";
import { useTheme } from "@/utils/theme/useTheme";
import FloatingAIButton from "@/components/FloatingAIButton";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const IS_TABLET = SCREEN_WIDTH >= 768;

// Responsive card width
const CARD_WIDTH = IS_TABLET ? SCREEN_WIDTH * 0.4 : SCREEN_WIDTH * 0.75;

const quickActions = [
  {
    id: "ai",
    title: "AI Assistant",
    icon: Sparkles,
    screen: "/ai-assistant",
    color: "#FFF630",
  },
  {
    id: "currency",
    title: "Currency",
    icon: DollarSign,
    screen: "/currency-converter",
    color: "#34C759",
  },
  {
    id: "essentials",
    title: "Essentials",
    icon: Package,
    screen: "/essentials",
    color: "#FF9500",
  },
];

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [destinations, setDestinations] = useState([]);
  const [featuredExperiences, setFeaturedExperiences] = useState([]);

  const [fontsLoaded] = useFonts({
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
    InstrumentSans_500Medium,
  });

  useEffect(() => {
    fetchDestinations();
    fetchExperiences();
  }, []);

  const fetchDestinations = async () => {
    try {
      const url = `${process.env.EXPO_PUBLIC_BASE_URL}/api/destinations?limit=10`;
      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        setDestinations(data.destinations || []);
      }
    } catch (error) {
      console.error("Error fetching destinations:", error);
    }
  };

  const fetchExperiences = async () => {
    try {
      const url = `${process.env.EXPO_PUBLIC_BASE_URL}/api/experiences?limit=5`;
      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        setFeaturedExperiences(data.experiences || []);
      }
    } catch (error) {
      console.error("Error fetching experiences:", error);
    }
  };

  const handleDestinationPress = (destination) => {
    router.push(`/destination/${destination.id}`);
  };

  if (!fontsLoaded) {
    return null;
  }

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      paddingHorizontal: IS_TABLET ? 48 : 24,
      paddingBottom: 20,
      alignItems: "center",
    },
    headerLogo: {
      width: IS_TABLET ? 200 : 160,
      height: IS_TABLET ? 62 : 50,
    },
    searchContainer: {
      paddingHorizontal: IS_TABLET ? 48 : 24,
      marginBottom: 24,
      maxWidth: IS_TABLET ? 800 : "100%",
      alignSelf: "center",
      width: "100%",
    },
    searchBar: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: theme.surface,
      borderRadius: 16,
      paddingHorizontal: 16,
      paddingVertical: IS_TABLET ? 18 : 14,
      borderWidth: 1,
      borderColor: theme.border,
    },
    searchInput: {
      flex: 1,
      fontFamily: "Poppins_400Regular",
      fontSize: IS_TABLET ? 17 : 15,
      color: theme.text,
      marginLeft: 12,
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingBottom: 20,
    },
    quickActionsContainer: {
      paddingHorizontal: IS_TABLET ? 48 : 24,
      marginBottom: 32,
      maxWidth: IS_TABLET ? 800 : "100%",
      alignSelf: "center",
      width: "100%",
    },
    quickActionsGrid: {
      flexDirection: "row",
      gap: IS_TABLET ? 16 : 12,
    },
    quickActionCard: {
      flex: 1,
      backgroundColor: theme.surface,
      borderRadius: 20,
      padding: IS_TABLET ? 28 : 20,
      alignItems: "center",
      borderWidth: 1,
      borderColor: theme.border,
    },
    quickActionIcon: {
      width: IS_TABLET ? 56 : 48,
      height: IS_TABLET ? 56 : 48,
      borderRadius: IS_TABLET ? 28 : 24,
      justifyContent: "center",
      alignItems: "center",
      marginBottom: 12,
    },
    quickActionTitle: {
      fontFamily: "Poppins_500Medium",
      fontSize: IS_TABLET ? 15 : 13,
      color: theme.text,
      textAlign: "center",
    },
    section: {
      marginBottom: 32,
    },
    sectionHeader: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingHorizontal: IS_TABLET ? 48 : 24,
      marginBottom: 16,
    },
    sectionTitle: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: IS_TABLET ? 24 : 20,
      color: theme.text,
    },
    seeAllButton: {
      flexDirection: "row",
      alignItems: "center",
    },
    seeAllText: {
      fontFamily: "Poppins_500Medium",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.accent,
      marginRight: 4,
    },
    destinationsScroll: {
      paddingLeft: IS_TABLET ? 48 : 24,
    },
    destinationCard: {
      width: CARD_WIDTH,
      marginRight: IS_TABLET ? 20 : 16,
      backgroundColor: theme.surface,
      borderRadius: 20,
      overflow: "hidden",
      borderWidth: 1,
      borderColor: theme.border,
    },
    destinationImage: {
      width: "100%",
      height: IS_TABLET ? 200 : 160,
      backgroundColor: theme.surface,
    },
    destinationContent: {
      padding: IS_TABLET ? 20 : 16,
    },
    destinationName: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: IS_TABLET ? 20 : 18,
      color: theme.text,
      marginBottom: 4,
    },
    destinationLocation: {
      fontFamily: "Poppins_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.textSecondary,
      marginBottom: 8,
    },
    destinationFooter: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
    },
    destinationRating: {
      flexDirection: "row",
      alignItems: "center",
    },
    ratingText: {
      fontFamily: "Poppins_500Medium",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.text,
      marginLeft: 4,
    },
    destinationPrice: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.accent,
    },
    experienceCard: {
      flexDirection: "row",
      backgroundColor: theme.surface,
      borderRadius: 16,
      marginHorizontal: IS_TABLET ? 48 : 24,
      marginBottom: 12,
      padding: IS_TABLET ? 16 : 12,
      borderWidth: 1,
      borderColor: theme.border,
      maxWidth: IS_TABLET ? 800 : "100%",
      alignSelf: "center",
      width: "100%",
    },
    experienceImage: {
      width: IS_TABLET ? 100 : 80,
      height: IS_TABLET ? 100 : 80,
      borderRadius: 12,
      backgroundColor: theme.surface,
      marginRight: 12,
    },
    experienceContent: {
      flex: 1,
      justifyContent: "space-between",
    },
    experienceTitle: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: IS_TABLET ? 17 : 15,
      color: theme.text,
      marginBottom: 4,
    },
    experienceCategory: {
      fontFamily: "Poppins_400Regular",
      fontSize: IS_TABLET ? 15 : 13,
      color: theme.textSecondary,
      marginBottom: 8,
    },
    experienceFooter: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
    },
    experiencePrice: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: IS_TABLET ? 18 : 16,
      color: theme.accent,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 20 }]}>
        <Image
          source={{
            uri: "https://ucarecdn.com/7a3f327f-1f72-4f06-98d0-0b38dfeeb1da/",
          }}
          style={styles.headerLogo}
          contentFit="contain"
          transition={100}
        />
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <TouchableOpacity
          style={styles.searchBar}
          onPress={() => router.push("/(tabs)/search")}
          activeOpacity={0.7}
        >
          <Search size={20} color={theme.iconSecondary} />
          <Text style={[styles.searchInput, { color: theme.textSecondary }]}>
            Search destinations, experiences...
          </Text>
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
        {/* Quick Actions */}
        <View style={styles.quickActionsContainer}>
          <View style={styles.quickActionsGrid}>
            {quickActions.map((action) => (
              <TouchableOpacity
                key={action.id}
                style={styles.quickActionCard}
                onPress={() => router.push(action.screen)}
                activeOpacity={0.7}
              >
                <View
                  style={[
                    styles.quickActionIcon,
                    { backgroundColor: action.color },
                  ]}
                >
                  <action.icon size={24} color="#1A1A1A" />
                </View>
                <Text style={styles.quickActionTitle}>{action.title}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Featured Destinations */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Popular Destinations</Text>
            <TouchableOpacity
              style={styles.seeAllButton}
              onPress={() => router.push("/search")}
            >
              <Text style={styles.seeAllText}>See all</Text>
              <ChevronRight size={16} color={theme.accent} />
            </TouchableOpacity>
          </View>

          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.destinationsScroll}
          >
            {destinations.map((destination) => (
              <TouchableOpacity
                key={destination.id}
                style={styles.destinationCard}
                activeOpacity={0.9}
                onPress={() => handleDestinationPress(destination)}
              >
                {destination.image_url && (
                  <Image
                    source={{ uri: destination.image_url }}
                    style={styles.destinationImage}
                    contentFit="cover"
                    transition={100}
                  />
                )}

                <View style={styles.destinationContent}>
                  <Text style={styles.destinationName} numberOfLines={1}>
                    {destination.name}
                  </Text>
                  <Text style={styles.destinationLocation} numberOfLines={1}>
                    {destination.country}
                  </Text>

                  <View style={styles.destinationFooter}>
                    <View style={styles.destinationRating}>
                      <Star
                        size={16}
                        color={theme.accent}
                        fill={theme.accent}
                      />
                      <Text style={styles.ratingText}>
                        {destination.rating || "4.5"}
                      </Text>
                    </View>
                    <Text style={styles.destinationPrice}>
                      {destination.price_range || "$$"}
                    </Text>
                  </View>
                </View>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        {/* Featured Experiences */}
        {featuredExperiences.length > 0 && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Local Experiences</Text>
              <TouchableOpacity
                style={styles.seeAllButton}
                onPress={() => router.push("/experiences")}
              >
                <Text style={styles.seeAllText}>See all</Text>
                <ChevronRight size={16} color={theme.accent} />
              </TouchableOpacity>
            </View>

            {featuredExperiences.map((experience) => (
              <TouchableOpacity
                key={experience.id}
                style={styles.experienceCard}
                activeOpacity={0.9}
              >
                {experience.image_url && (
                  <Image
                    source={{ uri: experience.image_url }}
                    style={styles.experienceImage}
                    contentFit="cover"
                    transition={100}
                  />
                )}

                <View style={styles.experienceContent}>
                  <View>
                    <Text style={styles.experienceTitle} numberOfLines={1}>
                      {experience.title}
                    </Text>
                    <Text style={styles.experienceCategory} numberOfLines={1}>
                      {experience.category || "Experience"}
                    </Text>
                  </View>

                  <View style={styles.experienceFooter}>
                    <Text style={styles.experiencePrice}>
                      ${experience.price || "0"}
                    </Text>
                  </View>
                </View>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Floating AI Assistant Button */}
      <FloatingAIButton />
    </View>
  );
}
